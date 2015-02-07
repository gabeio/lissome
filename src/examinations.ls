module.exports = exports = (app)->
	app
		..route '/:course/exams/:id?/:version?'
		.all app.locals.authorize
		.get (req, res, next)->
			res.send 'exams:index > '+JSON.stringify req.params

		..route '/:course/exams/:id?/:version?/edit'
		.all (req, res, next)->
			res.locals.needs = 2
			app.locals.authorize req, res, next
		.get (req, res, next)->
			res.send 'exams:edit > '+JSON.stringify req.params
