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
	User = app.locals.models.Users
	Course = app.locals.models.Course
	Post = app.locals.models.Post
	app
		..route '/:course/blog/:id?/:create(new|create)'
		.all (req, res, next)->
			res.locals.needs = 2
			app.locals.authorize req, res, next

		.all (req, res, next)->
			switch req.session.auth
			| 3
				err, result <- Course.find {
					'id': req.params.course
					'school': app.locals.school
				}
				if err
					winston.error 'course:find:blog', err
				else
					if !result? or result.length is 0
						next new Error 'NOT FOUND'
					else
						res.locals.course = result.0
						next!
			| 2
				err, result <- Course.find {
					'id': req.params.course
					'school': app.locals.school
					'faculty': mongoose.Types.ObjectId(req.session.uid)
				}
				if err
					winston.error 'course:find:blog', err
				else
					if !result? or result.length is 0
						next new Error 'NOT FOUND'
					else
						res.locals.course = result.0
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
			res.render 'blog', { +create }

		.post (req, res, next)->
			console.log req.body
			post = new Post {
				# uuid: res.locals.postuuid
				title: req.body.title
				text: req.body.body
				files: req.body.files
				author: mongoose.Types.ObjectId(req.session.uid)
				tags: []
				type: 'blog'
				school: app.locals.school
				course: mongoose.Types.ObjectId(res.locals.course._id)
			}
			err, post <- post.save
			if err
				winston.error 'blog post save', err
				res.render 'blog', { +create, -success }
			else
				winston.info 'blog post save', post
				res.render 'blog', { +create, +success }

		.put (req, res, next)->
			...
			# err, course <- Course.find {
			# 	'uid':req.params.course
			# 	'school':app.locals.school
			# }
			# if err
			# 	winston.error 'course:find '+err
			# if !course? or course.length is 0
			# 	next new Error 'NOT FOUND'
			# else
			# 	course = course.0
			# 	err, post <- Post.findOneAndUpdate {
			# 		'school': app.locals.school
			# 		'course': course.uuid
			# 		'type': 'blog'
			# 		'uuid': req.body.uuid
			# 	}
			# 	if err
			# 		winston.error 'post:update:blog', err
			# 	res.redirect '#'

		.delete (req, res, next)->
			...
			# err, course <- Course.find {
			# 	'id':req.params.course
			# 	'school':app.locals.school
			# }
			# if err
			# 	winston.error 'course:find '+err
			# if !course? or course.length is 0
			# 	next new Error 'NOT FOUND'
			# else
			# 	course = course.0
			# 	err, post <- Post.remove {
			# 		'_id': 
			# 		'school': app.locals.school
			# 		'course': course.uuid
			# 		'type': 'blog'
			# 		# 'uuid': req.body.uuid
			# 	}
			# 	res.redirect '#'

		..route '/:course/blog/:unique?'
		.all (req, res, next)->
			res.locals.needs = 1
			app.locals.authorize req, res, next

		.all (req, res, next)->
			switch req.session.auth
			| 3
				err, result <- Course.find {
					'id': req.params.course
					'school': app.locals.school
				}
				if err
					winston.error 'course:find:blog', err
				else
					if !result? or result.length is 0
						next new Error 'NOT FOUND'
					else
						res.locals.course = result.0
						next!
			| 2
				err, result <- Course.find {
					'id': req.params.course
					'school': app.locals.school
					'faculty': mongoose.Types.ObjectId(req.session.uid)
				}
				if err
					winston.error 'course:find:blog', err
				else
					if !result? or result.length is 0
						next new Error 'NOT FOUND'
					else
						res.locals.course = result.0
						next!
			| 1
				err, result <- Course.find {
					'id': req.params.course
					'school': app.locals.school
					'students': mongoose.Types.ObjectId(req.session.uid)
				}
				if err
					winston.error 'course:find:blog', err
				else
					if !result? or result.length is 0
						next new Error 'NOT FOUND'
					else
						res.locals.course = result.0
						next!
			| _
				next new Error 'UNAUTHORIZED'

		.get (req, res, next)->
			console.log 'ALPHA'
			res.locals.blog = []
			if req.params.unique?
				console.log 'b'
				async.series [
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
						console.log 'e'
						err, posts <- Post.find {
							'course':mongoose.Types.ObjectId(res.locals.course._id)
							'type':'blog'
							'title':req.params.unique
						}
						for post in posts
							res.locals.blog.push post
						done!
					(done)->
						# search tags
						console.log 'f'
						err, posts <- Post.find {
							'course':mongoose.Types.ObjectId(res.locals.course._id)
							'type':'blog'
							'tag':req.params.unique
						}
						for post in posts
							res.locals.blog.push post
						done!
					(done)->
						res.render 'blog'
						done!
				]
			else
				console.log 'a'
				err, post <- Post.find {
					'course':mongoose.Types.ObjectId(res.locals.course._id)
					'type':'blog'
				}
				res.locals.blog.push post.0
				# res.locals.blog = posts
				res.render 'blog'
