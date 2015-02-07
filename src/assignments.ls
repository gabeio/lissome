module.exports = (app)->
	app
		..route '/:course/assignments/:id?/:version?'
		.all app.locals.authorize
		.get (req, res, next)->
			res.send 'course:assignments:index > '+JSON.stringify req.params

		..route '/:course/assignments/:id?/:version?/edit'
		.all (req, res, next)->
			res.locals.needs = 2
			app.locals.authorize req, res, next
		.get (req, res, next)->
			res.send 'course:assignments:edit > '+JSON.stringify req.params
