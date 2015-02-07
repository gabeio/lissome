module.exports = exports = (app)->
	app
		..route '/:index(index|dash|dashboard)?'
		.all app.locals.authorize
		.get (req, res, next)->
			res.send 'index > '+JSON.stringify req.params

		..route '/preferences'
		.all app.locals.authorize
		.get (req, res, next)->
			res.send 'preferences > '+JSON.stringify req.params
