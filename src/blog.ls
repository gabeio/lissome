module.exports = (app)->
	require! {
		'lodash'
		'uuid'
	}
	_ = lodash
	winston = app.locals.winston
	models = app.locals.models
	app
		..route '/:course/blog/:id?/edit'
		.all (req, res, next)->
			res.locals.needs = 2
			app.locals.authorize req, res, next

		.get (req, res, next)->
			err, course <- models.Course.find {
				'id':req.params.course
				'school':app.locals.school
			}
			course = course.0
			if err?
				winston.error 'course:find '+err
			if !course? or course.length is 0
				next new Error 'NOT FOUND'
			else
				res.locals.blog = []
				for entry in course.blog
					# might need to find a better way to do this maybe just give up
					# and store inside the course blog array itself.
					err, post <- models.Post.find {
						'uuid':entry
					}
					res.locals.blog.push post
				res.render 'blog', { +edit }

		.post (req, res, next)->
			res.locals.postuuid = uuid.v4!
			post = new models.Post {
				uuid: res.locals.postuuid
				text: req.body.body
				files: req.body.files
				author: req.session.username
				time: new Date Date.now!
				title: req.body.title
			}
			err, post <- post.save
			winston.info 'post:save '+post
			err, course <- models.Course.findOneAndUpdate {
				'id':req.params.course
				'school':app.locals.school
			},{
				$push:{ 'blog': res.locals.postuuid } # pushes to property
			}
			course = course.0
			if err?
				winston.error 'course:find '+err
			if !course? or course.length is 0
				next new Error 'NOT FOUND'
			else
				res.locals.blog = course.blog.
				res.render 'blog'

		.put (req, res, next)->
			...

		.delete (req, res, next)->
			...

		..route '/:course/blog/:id?'
		.all (req, res, next)->
			res.locals.needs = 1
			app.locals.authorize req, res, next

		.get (req, res, next)->
			err, course <- models.Course.find { 'id':req.params.course, 'school':app.locals.school }
			course = course.0
			if err?
				winston.error 'course:find '+err
			if !course? or course.length is 0
				next new Error 'NOT FOUND'
			else
				res.locals.blog = []
				cont = lodash.once next
				for entry in course.blog
					# might need to find a better way to do this maybe just give up
					# and store inside the course blog array itself.
					console.log entry
					err, post <- models.Post.find {
						'uuid':entry
					}
					# console.log post
					res.locals.blog.push post.0
					console.log res.locals.blog
					cont!
		.get (req, res, next)->
			res.render 'blog'
