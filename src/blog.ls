module.exports = (app)->
	require! {
		'lodash'
		'uuid'
	}
	_ = lodash
	async = app.locals.async
	winston = app.locals.winston
	# models = app.locals.models
	User = app.locals.models.Users
	Course = app.locals.models.Course
	Post = app.locals.models.Post
	app
		..route '/:course/blog/:id?/edit'
		.all (req, res, next)->
			res.locals.needs = 2
			app.locals.authorize req, res, next

		.get (req, res, next)->
			err, course <- Course.find {
				'uid':req.params.course
				'school':app.locals.school
			}
			if err
				winston.error 'course:find '+err
			if !course? or course.length is 0
				next new Error 'NOT FOUND'
			else
				course = course.0
				err, posts <- Post.find {
					'course':course.uuid,
					'type':'blog'
				}
				console.log posts
				res.locals.blog = posts
				res.render 'blog', { +edit }

		.post (req, res, next)->
			err, course <- Course.find {
				'uid':req.params.course
				'school':app.locals.school
			}
			if err
				winston.error 'course:find '+err
			if !course? or course.length is 0
				next new Error 'NOT FOUND'
			else
				course = course.0
				res.locals.postuuid = uuid.v4!
				post = new Post {
					uuid: res.locals.postuuid
					title: req.body.title
					text: req.body.body
					files: req.body.files
					author: req.session.username
					tags: []
					type: 'blog'
					course: course.uuid
				}
				err, post <- post.save
				winston.info 'post:save '+post
				res.redirect '#'

		.put (req, res, next)->
			...

		.delete (req, res, next)->
			...

		..route '/:course/blog/:id?'
		.all (req, res, next)->
			res.locals.needs = 1
			app.locals.authorize req, res, next

		.get (req, res, next)->
			err, course <- Course.find { 'uid':req.params.course, 'school':app.locals.school }
			course = course.0
			if err
				winston.error 'course:find '+err
			if !course? or course.length is 0
				next new Error 'NOT FOUND'
			else
				# res.locals.blog = []
				err, posts <- Post.find {
					'course':course.uuid,
					'type':'blog'
				}
				console.log posts
				res.locals.blog = posts
				# for entry in posts
				# 	res.locals.blog.push entry
				# 	console.log res.locals.blog
				next!
		.get (req, res, next)->
			res.render 'blog'
