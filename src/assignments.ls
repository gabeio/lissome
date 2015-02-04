module.exports = exports = (app)->
	app
		..route '/:course/assignments/:id?/:version?'
		.all app.locals.authorize
		.get (req, res, next)->
			res.send 'assignments:index > '+JSON.stringify req.params

		..route '/:course/assignments/:id?/:version?/edit'
		.all (req, res, next)->
			res.locals.needs = "Faculty"
		.all app.locals.authorize
		.get (req, res, next)->
			res.send 'assignments:edit > '+JSON.stringify req.params
