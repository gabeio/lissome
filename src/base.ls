module.exports = exports = (app)->
	app
		..route '/login'
		.get (req, res, next)->
			# res.send 'base:login > '+JSON.stringify req.params
			res.render 'login'
		.post (req, res, next)->

			res.send 'base:login > '+JSON.stringify req.params

		..route '/:type(admin|teacher|student)?/:index(index|dash|dashboard)?'
		.get (req, res, next)->
			req.app.locals.winston.info 'test'
			res.send 'base:index > '+JSON.stringify req.params

		..route '/:type(admin|teacher|student)?/preferences'
		.get (req, res, next)->
			res.send 'base:preferences > '+JSON.stringify req.params
	require('./course')(app)
	require('./error')(app)
