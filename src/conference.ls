module.exports = (app)->
	require! {
		'async'
		'lodash'
		'mongoose'
	}
	_ = lodash
	User = app.locals.models.User
	Course = app.locals.models.Course
	Thread = app.locals.models.Thread
	Post = app.locals.models.Post
	app
		..route '/:course/:conf(conference|conf|c)/:thread?'
		.all (req, res, next)->
			# auth level check
			res.locals.needs = 1
			app.locals.authorize req, res, next
		.all (req, res, next)->
			# get course info middleware (helps with auth)
			res.locals.on = 'conference'
			<- async.parallel [
				(done)->
					if req.session.auth is 3
						err, result <- Course.findOne {
							'id': req.params.course
							'school': app.locals.school
						}
						if err
							winston.error 'course:findOne:blog:auth3', err
							next new Error 'INTERNAL'
						else
							if !result? or result.length is 0
								next new Error 'NOT FOUND'
							else
								res.locals.course = result
								done!
					else
						done!
				(done)->
					if req.session.auth is 2
						err, result <- Course.findOne {
							'id': req.params.course
							'school': app.locals.school
							'faculty': mongoose.Types.ObjectId(req.session.uid)
						}
						if err
							winston.error 'course:findOne:blog:auth2', err
							next new Error 'INTERNAL'
						else
							if !result? or result.length is 0
								next new Error 'NOT FOUND'
							else
								res.locals.course = result
								done!
					else
						done!
				(done)->
					if req.session.auth is 1
						err, result <- Course.findOne {
							'id': req.params.course
							'school': app.locals.school
							'students': mongoose.Types.ObjectId(req.session.uid)
						}
						if err
							winston.error 'course:findOne:blog:auth1', err
							next new Error 'INTERNAL'
						else
							if !result? or result.length is 0
								next new Error 'NOT FOUND'
							else
								res.locals.course = result
								done!
					else
						done!
			]
			next!
		.all (req, res, next)->
			# thread/post db middleware async for attempted max speed
			console.log 'course', res.locals.course
			<- async.parallel [
				(done)->
					console.log 'a'
					if req.params.thread?
						console.log 'b'
						err, posts <- Post.find {
							'course': mongoose.Types.ObjectId res.locals.course._id
							'type':'conference'
						}
						if err
							winston.error 'course:findOne:blog:auth1', err
							next new Error 'INTERNAL'
						else
							console.log 'c'
							res.locals.posts = posts
							done!
					else
						done!
				(done)->
					if !req.params.thread?
						err, result <- Thread.find {
							'course': mongoose.Types.ObjectId res.locals.course._id
							# 'type':'blog'
						}
						if err
							winston.error 'course:findOne:blog:auth1', err
							next new Error 'INTERNAL'
						else
							res.locals.threads = result
							done!
					else
						done!
			]
			console.log 'here'
			next!
		.get (req, res, next)->
			console.log 'threads', res.locals.threads
			res.render 'conference'
		.post (req, res, next)->
			...
		.put (req, res, next)->
			...
		.delete (req, res, next)->
			...
