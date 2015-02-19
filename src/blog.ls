module.exports = (app)->
	require! {
		'async'
		'lodash'
		'moment'
		'mongoose'
		'uuid'
		'winston'
	}
	_ = ld = lodash
	User = app.locals.models.User
	Course = app.locals.models.Course
	Post = app.locals.models.Post
	app
		..route '/:course/:blog(blog|b)/:id?/:action(new|edit)'
		.all (req, res, next)->
			res.locals.needs = 2
			app.locals.authorize req, res, next
		.all (req, res, next)->
			res.locals.on = 'blog'
			switch req.session.auth
			| 3
				err, result <- Course.findOne {
					'id': req.params.course
					'school': app.locals.school
				}
				if err
					winston.error 'course:findOne:blog', err
				else
					if !result? or result.length is 0
						next new Error 'NOT FOUND'
					else
						res.locals.course = result
						next!
			| 2
				err, result <- Course.findOne {
					'id': req.params.course
					'school': app.locals.school
					'faculty': mongoose.Types.ObjectId(req.session.uid)
				}
				if err
					winston.error 'course:findOne:blog', err
				else
					if !result? or result.length is 0
						next new Error 'NOT FOUND'
					else
						res.locals.course = result
						next!
			| _
				next new Error 'UNAUTHORIZED'
		.get (req, res, next)->
			# err, posts <- Post.find {
			# 	'course': mongoose.Types.ObjectId(res.locals.course._id)
			# 	'type': 'blog'
			# }
			# console.log 'posts',posts
			# res.locals.blog = posts
			res.render 'blog', { +create, 'blog':true, 'on':'newblog' }
		.post (req, res, next)->
			var authorName, authorUsername
			async.parallel [
				->
					res.render 'blog', { +create, 'blog':true, 'on':'newblog', success:'yes' } # return
				->
					authorUsername := req.session.username
					authorName := req.session.firstName+" "+req.session.lastName
					post = new Post {
						# uuid: res.locals.postuuid
						title: req.body.title
						text: req.body.body
						files: req.body.files
						author: mongoose.Types.ObjectId req.session.uid
						authorName: authorName
						authorUsername: authorUsername
						tags: []
						type: 'blog'
						school: app.locals.school
						course: mongoose.Types.ObjectId res.locals.course._id
					}
					err, post <- post.save
					if err?
						winston.error 'blog post save', err
			]
		.put (req, res, next)->
			async.parallel [
				->
					res.redirect '#'
				->
					err, post <- Post.findOneAndUpdate {
						'_id': mongoose.Types.ObjectId req.body.pid
						'school': app.locals.school
						'course': mongoose.Types.ObjectId res.locals.course._id
						'type': 'blog'
					}, {
						'title': res.body.title
						'text': res.body.text
					}
					if err
						winston.error 'blog post update', err
			]
		.delete (req, res, next)->
			async.parallel [
				->
					res.redirect '#'
				->
					err, post <- Post.remove {
						'_id': mongoose.Types.ObjectId req.body.pid
						'school': app.locals.school
						'course': mongoose.Types.ObjectId res.locals.course._id
						'type': 'blog'
					}
					if err
						winston.error 'blog post delete', err
			]
		..route '/:course/blog/:unique?'
		.all (req, res, next)->
			res.locals.needs = 1
			app.locals.authorize req, res, next
		.all (req, res, next)->
			res.locals.on = 'blog'
			switch req.session.auth
			| 3
				err, result <- Course.findOne {
					'id': req.params.course
					'school': app.locals.school
				}
				if err
					winston.error 'course:findOne:blog', err
				else
					if !result? or result.length is 0
						next new Error 'NOT FOUND'
					else
						res.locals.course = result
						next!
			| 2
				err, result <- Course.findOne {
					'id': req.params.course
					'school': app.locals.school
					'faculty': mongoose.Types.ObjectId(req.session.uid)
				}
				if err
					winston.error 'course:findOne:blog', err
				else
					if !result? or result.length is 0
						next new Error 'NOT FOUND'
					else
						res.locals.course = result
						next!
			| 1
				err, result <- Course.findOne {
					'id': req.params.course
					'school': app.locals.school
					'students': mongoose.Types.ObjectId(req.session.uid)
				}
				if err
					winston.error 'course:findOne:blog', err
				else
					if !result? or result.length is 0
						next new Error 'NOT FOUND'
					else
						res.locals.course = result
						next!
			| _
				next new Error 'UNAUTHORIZED'
		.get (req, res, next)->
			res.locals.blog = []
			if req.params.unique?
				err, posts <- async.parallel [
					# (done)->
					# 	# search date
					# 	if moment(req.params.unique).isValid!
					# 		console.log 'c'
					# 		err, posts <- Post.find {
					# 			'course':mongoose.Types.ObjectId(res.locals.course._id)
					# 			'type':'blog'
					# 			'title':req.params.unique
					# 		}
					# 		for post in posts
					# 			res.locals.blog.push post
					# 		console.log 'd'
					# 		done!
					# 	# if it's not a date don't do the search
					(done)->
						# search titles
						Post.find {
							'course': mongoose.Types.ObjectId(res.locals.course._id)
							'type': 'blog'
							'title': req.params.unique
						}, (err, posts)->
							done err, posts
					(done)->
						# search tags
						Post.find {
							'course': mongoose.Types.ObjectId(res.locals.course._id)
							'type': 'blog'
							'tags': req.params.unique
						}, (err, posts)->
							done err, posts
					(done)->
						# search authorName
						Post.find {
							'course': mongoose.Types.ObjectId(res.locals.course._id)
							'type': 'blog'
							'authorName': req.params.unique
						}, (err, posts)->
							done err, posts
				]
				posts = _.flatten posts, true
				res.render 'blog', blog: posts
			else
				err, posts <- Post.find {
					'course': mongoose.Types.ObjectId res.locals.course._id
					'type':'blog'
				}# } .sort {
				# 	date: 'descending'
				# } .exec
				console.log posts
				res.locals.blog = posts
				res.render 'blog'
