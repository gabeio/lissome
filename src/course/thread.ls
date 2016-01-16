require! {
	"express"
	"async"
	"lodash":"_"
	"mongoose"
	"winston"
	"../app"
}
parser = app.locals.multer.fields []
ObjectId = mongoose.Types.ObjectId
User = mongoose.models.User
Thread = mongoose.models.Thread
Post = mongoose.models.Post
router = express.Router!
router
	..route /^\/(.{24})\/?(newpost|editthread|deletethread|report)?$/i
	.all (req, res, next)->
		req.params.thread = req.params.0
		req.params.action? = req.params.1
		req.params.action = req.params.action.toLowerCase! if req.params.action?
		next!
	.all (req, res, next)->
		# thread/post db middleware async for attempted max speed
		err <- async.parallel [
			(para)->
				# get all the posts in that thread
				err, result <- Thread.findOne {
					"course": ObjectId res.locals.course._id
					"_id": ObjectId req.params.thread
				}
				.populate "author"
				.exec
				/* istanbul ignore if db error catcher */
				if err?
					para err
				else
					if result?
						res.locals.thread = result
						para!
					else
						para "NOT FOUND"
			(para)->
				# get all the posts in that thread
				err, result <- Post.find {
					"type": "conference"
					"course": ObjectId res.locals.course._id
					"thread": ObjectId req.params.thread
				}
				.populate "thread"
				.populate "author"
				.sort!
				.exec
				/* istanbul ignore if db error catcher */
				if err?
					para err
				else
					res.locals.posts? = result
					para!
		]
		if err
			winston.error "thread.ls: async.parallel", err
			next new Error err
		else
			next!
	.get (req, res, next)->
		/* istanbul ignore next only ignoring unimplemented */
		switch req.params.action
		| "editthread"
			res.render "course/conference/editThread", { csrf: req.csrfToken! }
		| "deletethread"
			res.render "course/conference/deleteThread", { csrf: req.csrfToken! }
		| "report"
			...
		| _
			res.render "course/conference/default", { csrf: req.csrfToken! }
	.post parser, (req, res, next)->
		switch req.params.action
		| "newpost"
			async.parallel [
				(para)->
					/* istanbul ignore else */
					if !req.body.thread? or req.body.thread is "" or !req.body.text? or req.body.text is ""
						res.status 400 .render "course/conference/default" { body: req.body, success:"no", noun:"Post", verb:"created", csrf: req.csrfToken! }
				(para)->
					/* istanbul ignore else */
					if req.body.thread? and req.body.thread isnt "" and req.body.text? and req.body.text isnt "" and res.locals.thread?
						res.status 302 .redirect "/c/#{res.locals.course._id}/thread/#{req.params.thread}"
				(para)->
					/* istanbul ignore else */
					if req.body.thread? and req.body.thread isnt "" and req.body.text? and req.body.text isnt "" and res.locals.thread?
						post = {
							course: res.locals.course._id
							author: ObjectId res.locals.uid
							thread: ObjectId req.body.thread
							text: req.body.text
							type: "conference"
						}
						post = new Post post
						err, post <- post.save
						/* istanbul ignore if db error catcher */
						winston.error "thread.ls: new Post.save", err if err
			]
		| "report"
			...
		| _
			next!
	.put parser, (req, res, next)->
		switch req.params.action
		| "editthread"
			if !req.body.thread? or !req.body.title? or req.body.title is ""
				res.status 400 .render "course/conference/editThread" { body: req.body, success:"no", noun:"Thread", verb:"edited", csrf: req.csrfToken! }
			else
				err, post <- Thread.findOneAndUpdate {
					_id: req.body.thread
					author: ObjectId res.locals.uid
				},{
					title: req.body.title
				}
				/* istanbul ignore if db error catcher */
				if err?
					winston.error "thread.ls: Thread.findOneAndUpdate", err
					next new Error "INTERNAL"
				else
					res.status 302 .redirect "/c/#{res.locals.course._id}/thread/#{req.params.thread}"
		| _
			next!
	.delete parser, (req, res, next)->
		switch req.params.action
		| "deletethread"
			if !req.body.thread?
				res.status 400 .render "course/conference/deleteThread" { body: req.body, success:"no", noun:"Thread", verb:"deleted", csrf: req.csrfToken! }
			else
				res.locals.theThread = {
					_id: ObjectId req.body.thread
					author: res.locals.uid
				}
				if res.locals.auth > 1
					delete res.locals.theThread.author
				# delete thread
				err, thread <- Thread.findOneAndRemove res.locals.theThread
				/* istanbul ignore if db error catcher */
				if err?
					# error might be that they are not author
					winston.error "thread.ls: Thread.findOneAndRemove", err
					res.status 400 .render "course/conference/deleteThread" { body: req.body, success:"no", noun:"Thread", verb:"deleted", csrf: req.csrfToken! }
				else
					if !thread?
						res.status 400 .render "course/conference/deleteThread" { body: req.body, success:"no", noun:"Posts", verb:"deleted", csrf: req.csrfToken! }
					else
						# delete posts of thread
						err, post <- Post.remove {
							thread: ObjectId thread._id
						}
						/* istanbul ignore if db error catcher */
						if err?
							winston.error "thread.ls: Post.Remove", err
							res.status 400 .render "course/conference/deleteThread" { body: req.body, success:"no", noun:"Posts", verb:"deleted", csrf: req.csrfToken! }
						else
							res.status 302 .redirect "/c/#{res.locals.course._id}/conference"
		| _
			next!

module.exports = router
