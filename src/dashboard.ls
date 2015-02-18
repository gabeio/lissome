module.exports = (app)->
	require! {
		'async'
		'lodash'
		'mongoose'
		'winston'
	}
	_ = lodash
	Course = app.locals.models.Course
	app
		..route '/:index(index|dash|dashboard)?'
		.all app.locals.authorize
		.get (req, res, next)->
			res.locals.on = 'dash'
			switch req.session.auth
			| 2
				err, courses <- Course.find {
					'school':app.locals.school
					'faculty':mongoose.Types.ObjectId(req.session.uid)
				}
				if err
					winston.error 'course:find', err
				else
					res.locals.courses = courses
					res.render 'dashboard'
			| 3
				err, courses <- Course.find {
					'school':app.locals.school
				}
				if err
					winston.error 'course:find', err
				else
					res.locals.courses = courses
					res.render 'dashboard'
			| _
				err, courses <- Course.find {
					'school':app.locals.school
					'students':mongoose.Types.ObjectId(req.session.uid)
				}
				if err
					winston.error 'course:find', err
				else
					res.locals.courses = courses
					res.render 'dashboard'

		..route '/preferences'
		.all app.locals.authorize
		.get (req, res, next)->
			res.locals.on = 'preferences'
			res.send 'preferences > '+JSON.stringify req.params
