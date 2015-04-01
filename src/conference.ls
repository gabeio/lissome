module.exports = (app)->
	require! {
		'async'
		'lodash'
		'mongoose'
		'winston'
	}
	ObjectId = mongoose.Types.ObjectId
	_ = lodash
	User = app.locals.models.User
	Course = app.locals.models.Course
	Thread = app.locals.models.Thread
	Post = app.locals.models.Post
	app
		..route '/:course/:conf(conference|conf|c)/:thread?' # query :: action(new|edit|delete)
		.all (req, res, next)->
			# auth level check
			res.locals.needs = 1
			app.locals.authorize req, res, next
		.all (req, res, next)->
			if req.query.action? then req.query.action = req.query.action.toLowerCase!
			if req.params.thread?
				if req.params.thread.length is 24
					next!
				else
					next new Error 'Bad Thread'
			else
				next!
		.all (req, res, next)->
			# get course info middleware (helps with auth)
			res.locals.on = 'conference'
			<- async.parallel [
				(done)->
					if res.locals.auth is 3
						err, result <- Course.findOne {
							'id': req.params.course
							'school': app.locals.school
						}
						/* istanbul ignore if */
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
					if res.locals.auth is 2
						err, result <- Course.findOne {
							'id': req.params.course
							'school': app.locals.school
							'faculty': ObjectId res.locals.uid
						}
						/* istanbul ignore if */
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
					if res.locals.auth is 1
						err, result <- Course.findOne {
							'id': req.params.course
							'school': app.locals.school
							'students': ObjectId res.locals.uid
						}
						/* istanbul ignore if */
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
			<- async.parallel [
				(done)->
					if !req.params.thread?
						err, result <- Thread.find {
							'course': ObjectId res.locals.course._id
						} .populate 'author' .exec
						/* istanbul ignore if */
						if err
							winston.error 'course:findOne:blog:auth1', err
							next new Error 'INTERNAL'
						else
							res.locals.threads = result
							done!
					else
						done!
				(done)->
					if req.params.thread?
						err, posts <- Post.find {
							'course': ObjectId res.locals.course._id
							'thread': ObjectId req.params.thread
							'type':'conference'
						} .populate 'thread' .populate 'author' .exec
						/* istanbul ignore if */
						if err
							winston.error 'course:findOne:blog:auth1', err
							next new Error 'INTERNAL'
						else
							if posts.length > 0
								res.locals.thread = posts.0.thread
							res.locals.posts = posts
							done!
					else
						done!
			]
			next!
		.get (req, res, next)->
			switch req.query.action
			| 'newthread'
				res.render 'conference/create'
			| _
				res.render 'conference/view'
		.post (req, res, next)->
			switch req.query.action
			| 'newpost'
				if !req.body.thread? || !req.body.text?
					res.status 400 .render 'conference/view' { body: req.body, success:'no', action:'new' }
				else
					post = {
						course: res.locals.course._id
						author: ObjectId res.locals.uid
						thread: ObjectId req.body.tid
						text: req.body.text
						type: 'conference'
					}
					post = new Post post
					err, post <- post.save
					if err?
						winston.error 'conf',err
						next new Error 'Mongo Error'
					else
						res.status 302 .redirect "/#{req.params.course}/conference/"+ req.params.thread
			| 'newthread'
				if !req.body.text?
					res.status 400 .render 'conference/create' { body: req.body, success:'no', action:'new' }
				else
					thread = {
						title: req.body.title
						author: ObjectId res.locals.uid
						course: ObjectId res.locals.course._id
					}
					thread = new Thread thread
					err, thread <- thread.save
					if err?
						winston.error 'thread',err
						next new Error 'Mongo Error'
					else
						post = {
							course: res.locals.course._id
							type: 'conference'
							author: ObjectId res.locals.uid
							thread: ObjectId thread._id
							text: req.body.text
						}
						post = new Post post
						err, post <- post.save
						if err?
							winston.error 'post',err
							next new Error 'Mongo Error'
						else
							res.status 302 .redirect "/#{req.params.course}/conference/"+ thread._id
			| _
				next new Error 'Action Error'
		.put (req, res, next)->
			switch req.query.action
			| 'edit'
				if !req.body.thread? || !req.body.text?
					res.status 400 .render 'conference/edit' { body: req.body, success:'no', action:'edit' }
				else
					err, post <- Post.findOneAndUpdate {
						_id: req.body.pid
						thread: req.body.thread
						author: ObjectId res.locals.uid
					},{
						text: req.body.text
					}
					if err?
						winston.error 'conf',err
						next new Error 'Mongo Error'
					else
						res.status 302 .redirect "/#{req.params.course}/conference/"+ req.params.thread
			| _
				next new Error 'Action Error'
		.delete (req, res, next)->
			switch req.query.action
			| 'delete'
				if !req.body.thread? || !req.body.text?
					res.status 400 .render 'conference/edit' { body: req.body, success:'no', action:'edit' }
				else
					err, post <- Post.findOneAndRemove {
						_id: req.body.pid
						thread: req.body.thread
						author: res.locals.uid
					}
			| _
				next new Error 'Action Error'
