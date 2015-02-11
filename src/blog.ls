module.exports = (app)->
	require! {
		'uuid'
	}
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
				res.locals.blog = course.blog
				res.render 'blog', { +edit }

		.post (req, res, next)->
			res.locals.postuuid = uuid.v4!
			post = new models.Post {
				uuid: res.locals.postuuid
				text: req.body.body
				files: ''
				author: req.session.username
				time: new Date Date.now!
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
				res.redner 'blog'

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
				res.locals.blog = course.blog
				res.render 'blog'
