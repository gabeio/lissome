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
		.all (req, res, next)->
			res.locals.needs = 1
			app.locals.authorize req, res, next
		.get (req, res, next)->
			res.locals.on = 'dash'
			<- async.parallel [
				(done)->
					if req.session.auth is 3
						err, courses <- Course.find {
							'school':app.locals.school
						}
						if err
							winston.error 'course:find', err
							next new Error 'INTERNAL'
						else
							res.locals.courses = courses
							done!
					else
						done!
				(done)->
					if req.session.auth is 2
						err, courses <- Course.find {
							'school':app.locals.school
							'faculty':mongoose.Types.ObjectId(req.session.uid)
						}
						if err
							winston.error 'course:find', err
							next new Error 'INTERNAL'
						else
							res.locals.courses = courses
							done!
					else
						done!
				(done)->
					if req.session.auth is 1
						err, courses <- Course.find {
							'school':app.locals.school
							'students':mongoose.Types.ObjectId(req.session.uid)
						}
						if err
							winston.error 'course:find', err
							next new Error 'INTERNAL'
						else
							res.locals.courses = courses
							done!
					else
						done!
			]
			res.render 'dashboard'
