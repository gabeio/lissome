/*
	this module is should only to load for testing.
*/
/* istanbul ignore next only for testing anyway */
module.exports = (app)->
	require! {
		"async"
		"mongoose"
		"winston"
	}
	parser = app.locals.multer.fields []
	ObjectId = mongoose.Types.ObjectId
	User = mongoose.models.User
	Course = mongoose.models.Course
	Post = mongoose.models.Post
	Assignment = mongoose.models.Assignment
	Attempt = mongoose.models.Attempt
	Thread = mongoose.models.Thread
	# winston = app.locals.winston
	winston.warn "TESTING MODE\nIF YOU SEE THIS MESSAGE THERE IS SOMETHING WRONG!!!"
	app
		..route "/test/:action/:more?"
		.all parser, (req, res, next)->
			switch req.params.action
			| "getauth"
				res.status 200 .send req.session.auth
			| "getroot"
				req.session.auth = 4
				res.status 200 .send "ok"
			| "getadmin"
				req.session.auth = 3
				res.status 200 .send "ok"
			| "getfaculty"
				req.session.auth = 2
				res.status 200 .send "ok"
			| "getstudent"
				req.session.auth = 1
				res.status 200 .send "ok"
			| "getaid"
				err, result <- Course.findOne {
					"id": req.params.more
					"school": app.locals.school
				}
				if err
					winston.error "test:course:findOne:blog", err
					next new Error "INTERNAL"
				else
					assign = {
						"course": ObjectId result._id
					}
					if req.query.title?
						assign.title = req.query.title
					err, result <- Assignment.find assign
					if err
						winston.error "test:course:find:assignment", err
						next new Error "INTERNAL"
					else
						res.json result
			| "getattempt"
				err, result <- Course.findOne {
					"id": req.params.more
					"school": app.locals.school
				}
				if err
					winston.error "test:course:findOne:blog", err
					next new Error "INTERNAL"
				else
					err, result <- Assignment.findOne {
						"course": ObjectId result._id
						"title": req.query.title
					}
					if err
						winston.error "test:course:find:assignment", err
						next new Error "INTERNAL"
					else
						err, result <- Attempt.find {
							"assignment": ObjectId result._id
							"text": req.query.text
						}
						if err
							winston.error "test:course:find:assignment", err
							next new Error "INTERNAL"
						else
							res.json result
			| "getattemptof"
				err, result <- Course.findOne {
					"id": req.params.more
					"school": app.locals.school
				}
				if err
					winston.error "test:course:findOne:blog", err
					next new Error "INTERNAL"
				else
					err, result <- Assignment.findOne {
						"course": ObjectId result._id
						"title": req.query.title
					}
					if err
						winston.error "test:course:find:assignment", err
						next new Error "INTERNAL"
					else
						err, result <- Attempt.find {
							"assignment": ObjectId result._id
							"text": req.query.text
							"author": ObjectId req.query.author
						}
						if err
							winston.error "test:course:find:assignment", err
							next new Error "INTERNAL"
						else
							res.json result
			| "getpid"
				err, result <- Course.findOne {
					"id": req.params.more
					"school": app.locals.school
				}
				if err
					winston.error "test:course:findOne:blog", err
					next new Error "INTERNAL"
				else
					res.locals.course = result
					err, result <- Post.find {
						"course": ObjectId(res.locals.course._id)
						"type": "blog"
					}
					if err
						winston.error "test:course:find:post", err
						next new Error "INTERNAL"
					else
						res.json result
			| "gettid"
				err, result <- Course.findOne {
					"id": req.params.more
					"school": app.locals.school
				}
				if err
					winston.error "test:course:findOne:blog", err
					next new Error "INTERNAL"
				else
					res.locals.course = result
					err, result <- Thread.find {
						"course": ObjectId(res.locals.course._id)
						"title": req.query.title
					}
					if err
						winston.error "test:course:find:post", err
						next new Error "INTERNAL"
					else
						res.json result
			| "getpost"
				err, result <- Course.findOne {
					"id": req.params.more
					"school": app.locals.school
				}
				if err
					winston.error "test:course:findOne:blog", err
					next new Error "INTERNAL"
				else
					res.locals.course = result
					err, result <- Post.find {
						"course": ObjectId(res.locals.course._id)
						"type": "conference"
						"text": new RegExp req.query.text, "i"
					} .populate "thread" .exec
					if err
						winston.error "test:course:find:post", err
						next new Error "INTERNAL"
					else
						res.json result
			| "postblog"
				err, result <- Course.findOne {
					"id": req.body.course
					"school": app.locals.school
				}
				if err
					winston.error "course:findOne:blog:auth3", err
					next new Error "INTERNAL"
				else
					if !result? or result.length is 0
						next new Error "NOT FOUND"
					else
						res.locals.course = result
						authorUsername = req.session.username
						authorName = req.session.firstName+" "+req.session.lastName
						post = new Post {
							title: encodeURIComponent req.body.title
							text: req.body.text
							# files: req.body.files
							author: ObjectId req.session.uid
							authorName: authorName
							authorUsername: authorUsername
							tags: []
							type: "blog"
							school: app.locals.school
							course: ObjectId res.locals.course._id
						}
						err, post <- post.save
						res.json post
			| "deleteassignments"
				err, result <- Course.findOne {
					"id": req.params.more
					"school": app.locals.school
				}
				if err
					winston.error "test:course:findOne:blog", err
					next new Error "INTERNAL"
				else
					res.locals.course = result
					<- async.parallel [
						(done)->
							err, result <- Assignment.remove {}
							if err
								winston.error "test:course:remove:assignment", err
								next new Error "INTERNAL"
							else
								done!
						(done)->
							err, result <- Attempt.remove {}
							if err
								winston.error "test:course:remove:assignment", err
								next new Error "INTERNAL"
							else
								done!
					]
					res.send "ok"
			| "deletethreads"
				err, result <- Course.findOne {
					"id": req.params.more
					"school": app.locals.school
				}
				if err
					winston.error "test:course:findOne:blog", err
					next new Error "INTERNAL"
				else
					res.locals.course = result
					err, result <- async.parallel [
						(done)->
							err, result <- Thread.remove {}
							if err
								winston.error "test:course:remove:post", err
								next new Error "INTERNAL"
							else
								done err, result
						(done)->
							err, result <- Post.remove {}
							if err
								winston.error "test:course:remove:post", err
								next new Error "INTERNAL"
							else
								done err, result
					]
					if err
						winston.error
					res.json result
			| "deleteposts"
				err, result <- Course.findOne {}
				if err
					winston.error "test:course:findOne:blog", err
					next new Error "INTERNAL"
				else
					res.locals.course = result
					err, result <- Post.remove {
						course: ObjectId result._id
					}
					if err
						winston.error "test:course:find:post", err
						next new Error "INTERNAL"
					else
						res.json result
			| _
				...
