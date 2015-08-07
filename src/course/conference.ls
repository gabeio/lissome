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
	..route "/:action?"
	.all (req, res, next)->
		if req.params.action? then req.params.action = req.params.action.toLowerCase!
		next!
	.all (req, res, next)->
		# get all threads in the course
		err, result <- Thread.find {
			"course": ObjectId res.locals.course._id
		}
		.populate "author"
		.sort {timestamp: -1}
		.exec
		/* istanbul ignore if should only really occur if db crashes */
		if err
			winston.error "conference.ls: Thread.find", err
			next new Error "MONGO"
		else
			res.locals.threads? = result
			next!
	.get (req, res, next)->
		switch req.params.action
		| "newthread"
			res.render "course/conference/create", { csrf: req.csrfToken! }
		| "report"
			...
		| _
			res.render "course/conference/default", { csrf: req.csrfToken! }
	.post parser, (req, res, next)->
		switch req.params.action
		| "newthread"
			if !req.body.title? or req.body.title is "" or !req.body.text? or req.body.text is ""
				res.status 400 .render "course/conference/create" { body: req.body, success:"no", noun:"Thread", verb:"created", csrf: req.csrfToken! }
			else
				err <- async.waterfall [
					(done)->
						thread = {
							title: req.body.title
							author: ObjectId res.locals.uid
							course: ObjectId res.locals.course._id
						}
						thread = new Thread thread
						err, thread <- thread.save
						done err,thread
					(thread,done)->
						res.status 302 .redirect "/c/#{res.locals.course._id}/thread/#{thread._id}"
						done null,thread
					(thread,done)->
						post = {
							course: res.locals.course._id
							type: "conference"
							author: ObjectId res.locals.uid
							thread: ObjectId thread._id
							text: req.body.text
						}
						post = new Post post
						err, post <- post.save
						winston.error "conference.ls new Post.save", err if err # this way it doesn't try to double send response
						done null
				]
				if err
					winston.error "conference.ls new Thread.save", err
					next new Error err
		| "report"
			...
		| _
			next!

module.exports = router
