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
	..route /^\/(.{24})\/?(editpost|deletepost|report)?$/i
	.all (req, res, next)->
		req.params.post = req.params.0
		req.params.action? = req.params.1
		req.params.action = req.params.action.toLowerCase! if req.params.action?
		next!
	.all (req, res, next)->
		# one post
		err, result <- Post.findOne {
			"type":"conference"
			"course": ObjectId res.locals.course._id
			"_id": ObjectId req.params.post
		}
		.populate "thread"
		.populate "author"
		.exec
		/* istanbul ignore if should only really occur if db crashes */
		if err
			winston.error "post.ls: post.findOne", err
			next new Error "MONGO"
		else
			if result?
				res.locals.post? = result
				res.locals.posts? = result
				res.locals.thread? = result.thread
				next!
			else
				next new Error "NOT FOUND"
	.get (req, res, next)->
		switch req.params.action
		| "editpost"
			res.render "course/conference/editPost", { csrf: req.csrfToken! }
		| "deletepost"
			res.render "course/conference/deletePost", { csrf: req.csrfToken! }
		| "report"
			...
		| _
			next!
	.all (req, res, next)->
		if req.method.toLowerCase! in ["post","put","delete"]
			err <- async.parallel [
				(done)->
					if !req.body.thread? or req.body.thread is "" or req.body.thread.length isnt 24
						done "Bad Thread"
					else
						done!
				(done)->
					if !req.body.post? or req.body.post is "" or req.body.post.length isnt 24
						done "Bad Post"
					else
						done!
			]
			if err
				next new Error err
			else
				next!
		else
			next!
	.post parser, (req, res, next)->
		switch req.params.action
		| "report"
			...
		| _
			next!
	.put parser, (req, res, next)->
		switch req.params.action
		| "editpost"
			if !req.body.thread? or req.body.thread is "" or !req.body.post? or req.body.post is "" or !req.body.text? or req.body.text is ""
				res.status 400 .render "course/conference/editPost" { body: req.body, success:"no", noun:"Post", verb:"edited", csrf: req.csrfToken! }
			else
				err, post <- Post.findOneAndUpdate {
					_id: req.body.post
					thread: req.body.thread
					author: ObjectId res.locals.uid
				},{
					text: req.body.text
				}
				/* istanbul ignore if should only really occur if db crashes */
				if err?
					winston.error "post.ls: Post.findOneAndUpdate", err
					next new Error "INTERNAL"
				else
					res.status 302 .redirect "/c/#{res.locals.course._id}/thread/#{res.locals.thread._id}"
		| _
			next!
	.delete parser, (req, res, next)->
		switch req.params.action
		| "deletepost"
			if !req.body.thread? or req.body.thread is "" or !req.body.post? or req.body.post is ""
				res.status 400 .render "course/conference/deletePost" { body: req.body, success:"no", noun:"Post", verb:"deleted", csrf: req.csrfToken! }
			else
				res.locals.thePost =  {
					_id: ObjectId req.body.post
					thread: ObjectId req.body.thread
					author: res.locals.uid
				}
				if res.locals.auth > 1
					delete res.locals.thePost.author
				# delete post
				err, post <- Post.findOneAndRemove res.locals.thePost
				/* istanbul ignore if should only really occur if db crashes */
				if err?
					winston.error err
					res.status 400 .render "course/conference/deletePost" { body: req.body, success:"no", noun:"Post", verb:"deleted", csrf: req.csrfToken! }
				else
					res.status 302 .redirect "/c/#{res.locals.course._id}/thread/#{res.locals.thread._id}"
		| _
			next!

module.exports = router
