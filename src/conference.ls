module.exports = exports = (app)->
	app
		..route '/:course/conference/:thread?'
		.all app.locals.authorize
		.get (req, res, next)->
			res.send 'conference:index > '+JSON.stringify req.params
