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
		..route '/:course/conference/:thread?/:post?' # query :: action(new|edit|delete)
		.all (req, res, next)->
			# auth level check
			res.locals.needs = 1
			app.locals.authorize req, res, next
		.all (req, res, next)->
			if req.query.action? then req.query.action = req.query.action.toLowerCase!
			if req.params.thread? and req.params.thread.length isnt 24
				next new Error 'Bad Thread'
			else if req.params.post? and req.params.post.length isnt 24
				next new Error 'Bad Post'
			else
				res.locals.course = {
					'id': req.params.course
					'school': app.locals.school
				}
				switch res.locals.auth
				| 3
					next!
				| 2
					res.locals.course.faculty = ObjectId res.locals.uid
					next!
				| 1
					res.locals.course.students = ObjectId res.locals.uid
					next!
				| _
					next new Error 'UNAUTHORIZED'
		.all (req, res, next)->
			err, result <- Course.findOne res.locals.course
			if err
				winston.error 'course findOne conf', err
				next new Error 'INTERNAL'
			else
				if !result? or result.length is 0
					next new Error 'NOT FOUND'
				else
					res.locals.course = result
					next!
		.all (req, res, next)->
			# thread/post db middleware async for attempted max speed
			<- async.parallel [
				(done)->
					if !req.params.thread?
						err, result <- Thread.find {
							'course': ObjectId res.locals.course._id
						} .populate 'author' .sort!.exec
						if err
							winston.error 'course:findOne:blog:auth1', err
							next new Error 'INTERNAL'
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
									'course': ObjectId res.locals.course._id
									'_id': ObjectId req.params.thread
								} .populate 'author' .exec
								if err
									winston.error 'conf find thread', err
									next new Error 'INTERNAL'
								else
									if result?
										res.locals.thread = result
										done!
									else
										next new Error 'NOT FOUND'
							(done)->
								err, result <- Post.find {
									'type': 'conference'
									'course': ObjectId res.locals.course._id
									'thread': ObjectId req.params.thread
								} .populate 'thread' .populate 'author' .sort!.exec
								if err
									winston.error 'conf find thread', err
									next new Error 'INTERNAL'
								else
									if result?
										res.locals.posts = result
										done!
									else
										next new Error 'NOT FOUND'
						]
						done!
					else
						done!
				(done)->
					if req.params.post?
						err, result <- Post.findOne {
							'type':'conference'
							'course': ObjectId res.locals.course._id
							'_id': ObjectId req.params.post
						} .populate 'thread' .populate 'author' .exec
						if err
							winston.error 'course:findOne:blog:auth1', err
							next new Error 'INTERNAL'
						else
							if !result?
								next new Error 'NOT FOUND'
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
			| 'newthread'
				res.render 'conference/create'
			| 'editthread'
				res.render 'conference/editthread'
			| 'editpost'
				res.render 'conference/editpost'
			| 'deletethread'
				res.render 'conference/delthread'
			| 'deletepost'
				res.render 'conference/delpost'
			| 'report'
				...
			| _
				res.render 'conference/view'
		.post (req, res, next)->
			switch req.query.action
			| 'newpost'
				if !req.body.thread? or req.body.thread is "" or !req.body.text? or req.body.text is ""
					res.status 400 .render 'conference/view' { body: req.body, success:'no', noun:'Post', verb:'created' }
				else
					async.parallel [
						(done)->
							res.status 302 .redirect "/#{req.params.course}/conference/#{req.params.thread}"
						(done)->
							if res.locals.thread?
								# console.log 'created post!'
								# console.log res.locals.thread
								post = {
									course: res.locals.course._id
									author: ObjectId res.locals.uid
									thread: ObjectId req.body.thread
									text: req.body.text
									type: 'conference'
								}
								post = new Post post
								err, post <- post.save
								if err?
									winston.error 'conf',err
									# next new Error 'Mongo Error'
					]
			| 'newthread'
				if !req.body.title? or req.body.title is "" or !req.body.text? or req.body.text is ""
					res.status 400 .render 'conference/create' { body: req.body, success:'no', noun:'Thread', verb:'created' }
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
							res.status 302 .redirect "/#{req.params.course}/conference/#{thread._id}"
			| 'report'
				...
			| _
				next new Error 'Action Error'
		.put (req, res, next)->
			switch req.query.action
			| 'editpost'
				if !req.body.thread? or !req.body.post? or !req.body.text? or req.body.text is ""
					res.status 400 .render 'conference/editpost' { body: req.body, success:'no', noun:'Post', verb:'edited' }
				else
					err, post <- Post.findOneAndUpdate {
						_id: req.body.post
						thread: req.body.thread
						author: ObjectId res.locals.uid
					},{
						text: req.body.text
					}
					if err?
						winston.error 'conf' err
						next new Error 'Mongo Error'
					else
						res.status 302 .redirect "/#{req.params.course}/conference/#{req.params.thread}"
			| 'editthread'
				if !req.body.thread? or !req.body.title? or req.body.title is ""
					res.status 400 .render 'conference/editthread' { body: req.body, success:'no', noun:'Thread', verb:'edited' }
				else
					err, post <- Thread.findOneAndUpdate {
						_id: req.body.thread
						author: ObjectId res.locals.uid
					},{
						title: req.body.title
					}
					if err?
						winston.error 'conf' err
						next new Error 'Mongo Error'
					else
						res.status 302 .redirect "/#{req.params.course}/conference/#{req.params.thread}"
			| _
				next new Error 'Action Error'
		.delete (req, res, next)->
			switch req.query.action
			| 'deletepost'
				if !req.body.thread? or !req.body.post?
					res.status 400 .render 'conference/delpost' { body: req.body, success:'no', noun:'Post', verb:'deleted' }
				else
					thePost =  {
						_id: ObjectId req.body.post
						thread: ObjectId req.body.thread
						author: res.locals.uid
					}
					if res.locals.auth > 1
						delete thePost.author
					err, post <- Post.findOneAndRemove thePost
					if err?
						winston.error err
						res.status 400 .render 'conference/delpost' { body: req.body, success:'no', noun:'Post', verb:'deleted' }
					else
						res.status 302 .redirect "/#{req.params.course}/conference/#{req.params.thread}"
			| 'deletethread'
				if !req.body.thread?
					res.status 400 .render 'conference/delthread' { body: req.body, success:'no', noun:'Thread', verb:'deleted' }
				else
					theThread = {
						_id: ObjectId req.body.thread
						author: res.locals.uid
					}
					if res.locals.auth > 1
						delete theThread.author
					# first delete thread
					err, thread <- Thread.findOneAndRemove theThread
					if err?
						# error might be that they are not author
						winston.error err
						res.status 400 .render 'conference/delthread' { body: req.body, success:'no', noun:'Thread', verb:'deleted' }
					else
						err, post <- Post.remove {
							thread: ObjectId req.body.thread
						}
						if err?
							winston.error err
							res.status 400 .render 'conference/delthread' { body: req.body, success:'no', noun:'Posts', verb:'deleted' }
						else
							res.status 302 .redirect "/#{req.params.course}/conference"
			| _
				next new Error 'Action Error'
