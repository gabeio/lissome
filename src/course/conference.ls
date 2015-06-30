require! {
	"express"
	"async"
	"lodash"
	"mongoose"
	"winston"
	"../app"
}
ObjectId = mongoose.Types.ObjectId
_ = lodash
User = mongoose.models.User
Course = mongoose.models.Course
Thread = mongoose.models.Thread
Post = mongoose.models.Post
router = express.Router!
router
	..route "/:course/conference/:thread?/:post?" # query :: action(new|edit|delete)
	.all (req, res, next)->
		# auth level check
		res.locals.needs = 1
		app.locals.authorize req, res, next
	.all (req, res, next)->
		if req.query.action? then req.query.action = req.query.action.toLowerCase!
		if req.params.thread? and req.params.thread.length isnt 24
			next new Error "Bad Thread"
		else if req.params.post? and req.params.post.length isnt 24
			next new Error "Bad Post"
		else
			res.locals.course = {
				"id": req.params.course
				"school": app.locals.school
			}
			/* istanbul ignore else there should be no way to hit that. */
			if res.locals.auth >= 3
				next!
			else if res.locals.auth is 2
				res.locals.course.faculty = ObjectId res.locals.uid
				next!
			else if res.locals.auth is 1
				res.locals.course.students = ObjectId res.locals.uid
				next!
			else
				next new Error "UNAUTHORIZED"
	.all (req, res, next)->
		err, result <- Course.findOne res.locals.course
		/* istanbul ignore if should only really occur if db crashes */
		if err?
			winston.error "course findOne conf", err
			next new Error "INTERNAL"
		else
			if !result? or result.length is 0
				next new Error "NOT FOUND"
			else
				res.locals.course = result
				next!
	.all (req, res, next)->
		# thread/post db middleware async for attempted max speed
		<- async.parallel [
			(done)->
				if !req.params.thread?
					err, result <- Thread.find {
						"course": ObjectId res.locals.course._id
					} .populate "author" .sort!.exec
					/* istanbul ignore if should only really occur if db crashes */
					if err?
						winston.error "course:findOne:blog:auth1", err
						next new Error "INTERNAL"
					else
						res.locals.threads = result
						done!
				else
					done!
			(done)->
				if req.params.thread? && !req.params.post?
					<- async.parallel [
						(done)->
							err, result <- Thread.findOne {
								"course": ObjectId res.locals.course._id
								"_id": ObjectId req.params.thread
							} .populate "author" .exec
							/* istanbul ignore if should only really occur if db crashes */
							if err?
								winston.error "conf find thread", err
								next new Error "INTERNAL"
							else
								if result?
									res.locals.thread = result
									done!
								else
									next new Error "NOT FOUND"
						(done)->
							err, result <- Post.find {
								"type": "conference"
								"course": ObjectId res.locals.course._id
								"thread": ObjectId req.params.thread
							} .populate "thread" .populate "author" .sort!.exec
							/* istanbul ignore if should only really occur if db crashes */
							if err?
								winston.error "conf find thread", err
								next new Error "INTERNAL"
							else
								/* istanbul ignore else honestly don't know how to hit the else */
								if result?
									res.locals.posts = result
									done!
								else
									next new Error "NOT FOUND"
					]
					done!
				else
					done!
			(done)->
				if req.params.post?
					err, result <- Post.findOne {
						"type":"conference"
						"course": ObjectId res.locals.course._id
						"_id": ObjectId req.params.post
					} .populate "thread" .populate "author" .exec
					/* istanbul ignore if should only really occur if db crashes */
					if err?
						winston.error "course:findOne:blog:auth1", err
						next new Error "INTERNAL"
					else
						if !result?
							next new Error "NOT FOUND"
						else
							res.locals.thread = result.thread
							res.locals.post = result
							done!
				else
					done!
		]
		next!
	.get (req, res, next)->
		switch req.query.action
		| "newthread"
			res.render "course/conference/create", { csrf: req.csrfToken! }
		| "editthread"
			res.render "course/conference/editthread", { csrf: req.csrfToken! }
		| "editpost"
			res.render "course/conference/editpost", { csrf: req.csrfToken! }
		| "deletethread"
			res.render "course/conference/delthread", { csrf: req.csrfToken! }
		| "deletepost"
			res.render "course/conference/delpost", { csrf: req.csrfToken! }
		| "report"
			...
		| _
			res.render "course/conference/view", { csrf: req.csrfToken! }
	.post (req, res, next)->
		switch req.query.action
		| "newpost"
			if !req.body.thread? or req.body.thread is "" or !req.body.text? or req.body.text is ""
				res.status 400 .render "course/conference/view" { body: req.body, success:"no", noun:"Post", verb:"created", csrf: req.csrfToken! }
			else
				async.parallel [
					(done)->
						res.status 302 .redirect "/c/#{req.params.course}/conference/#{req.params.thread}"
					(done)->
						if res.locals.thread?
							# console.log "created post!"
							# console.log res.locals.thread
							post = {
								course: res.locals.course._id
								author: ObjectId res.locals.uid
								thread: ObjectId req.body.thread
								text: req.body.text
								type: "conference"
							}
							post = new Post post
							err, post <- post.save
							/* istanbul ignore if should only really occur if db crashes */
							if err?
								winston.error "conf",err
								# next new Error "Mongo Error"
				]
		| "newthread"
			if !req.body.title? or req.body.title is "" or !req.body.text? or req.body.text is ""
				res.status 400 .render "course/conference/create" { body: req.body, success:"no", noun:"Thread", verb:"created", csrf: req.csrfToken! }
			else
				thread = {
					title: req.body.title
					author: ObjectId res.locals.uid
					course: ObjectId res.locals.course._id
				}
				thread = new Thread thread
				err, thread <- thread.save
				/* istanbul ignore if should only really occur if db crashes */
				if err?
					winston.error "thread",err
					next new Error "Mongo Error"
				else
					post = {
						course: res.locals.course._id
						type: "conference"
						author: ObjectId res.locals.uid
						thread: ObjectId thread._id
						text: req.body.text
					}
					post = new Post post
					err, post <- post.save
					/* istanbul ignore if should only really occur if db crashes */
					if err?
						winston.error "post",err
						next new Error "Mongo Error"
					else
						res.status 302 .redirect "/c/#{req.params.course}/conference/#{thread._id}"
		| "report"
			...
		| _
			next new Error "Action Error"
	.put (req, res, next)->
		switch req.query.action
		| "editpost"
			if !req.body.thread? or !req.body.post? or !req.body.text? or req.body.text is ""
				res.status 400 .render "course/conference/editpost" { body: req.body, success:"no", noun:"Post", verb:"edited", csrf: req.csrfToken! }
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
					winston.error "conf" err
					next new Error "INTERNAL"
				else
					res.status 302 .redirect "/c/#{req.params.course}/conference/#{req.params.thread}"
		| "editthread"
			if !req.body.thread? or !req.body.title? or req.body.title is ""
				res.status 400 .render "course/conference/editthread" { body: req.body, success:"no", noun:"Thread", verb:"edited", csrf: req.csrfToken! }
			else
				err, post <- Thread.findOneAndUpdate {
					_id: req.body.thread
					author: ObjectId res.locals.uid
				},{
					title: req.body.title
				}
				/* istanbul ignore if should only really occur if db crashes */
				if err?
					winston.error "conf" err
					next new Error "INTERNAL"
				else
					res.status 302 .redirect "/c/#{req.params.course}/conference/#{req.params.thread}"
		| _
			next new Error "Action Error"
	.delete (req, res, next)->
		switch req.query.action
		| "deletepost"
			if !req.body.thread? or !req.body.post?
				res.status 400 .render "course/conference/delpost" { body: req.body, success:"no", noun:"Post", verb:"deleted", csrf: req.csrfToken! }
			else
				res.locals.thePost =  {
					_id: ObjectId req.body.post
					thread: ObjectId req.body.thread
					author: res.locals.uid
				}
				if res.locals.auth > 1
					delete res.locals.thePost.author
				err, post <- Post.findOneAndRemove res.locals.thePost
				/* istanbul ignore if should only really occur if db crashes */
				if err?
					winston.error err
					res.status 400 .render "course/conference/delpost" { body: req.body, success:"no", noun:"Post", verb:"deleted", csrf: req.csrfToken! }
				else
					res.status 302 .redirect "/c/#{req.params.course}/conference/#{req.params.thread}"
		| "deletethread"
			if !req.body.thread?
				res.status 400 .render "course/conference/delthread" { body: req.body, success:"no", noun:"Thread", verb:"deleted", csrf: req.csrfToken! }
			else
				res.locals.theThread = {
					_id: ObjectId req.body.thread
					author: res.locals.uid
				}
				if res.locals.auth > 1
					delete res.locals.theThread.author
				# first delete thread
				err, thread <- Thread.findOneAndRemove res.locals.theThread
				/* istanbul ignore if should only really occur if db crashes */
				if err?
					# error might be that they are not author
					winston.error err
					res.status 400 .render "course/conference/delthread" { body: req.body, success:"no", noun:"Thread", verb:"deleted", csrf: req.csrfToken! }
				else
					if thread?
						err, post <- Post.remove {
							thread: ObjectId thread._id
						}
						/* istanbul ignore if should only really occur if db crashes */
						if err?
							winston.error err
							res.status 400 .render "conference/delthread" { body: req.body, success:"no", noun:"Posts", verb:"deleted", csrf: req.csrfToken! }
						else
							res.status 302 .redirect "/c/#{req.params.course}/conference"
					else
						res.status 400 .render "conference/delthread" { body: req.body, success:"no", noun:"Posts", verb:"deleted", csrf: req.csrfToken! }
		| _
			next new Error "Action Error"

module.exports = router
