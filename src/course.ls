module.exports = (app)->
	app
		..route '/:course/:index(index|dash|dashboard)?'
		.all app.locals.authorize
		.get (req, res, next)->
			res.send 'course:index > '+JSON.stringify req.params

		..route '/:course/edit'
		.all (req, res, next)->
			res.locals.needs = 2
			app.locals.authorize req, res, next
		.get (req, res, next)->
			# if app.req.locals.isTeacher(req) or app.req.locals.isAdmin(req)
			res.send 'course:edit > '+JSON.stringify req.params
