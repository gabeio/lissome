module.exports = (app)->
	app
		..route '/:course/conference/:thread?'
		.all app.locals.authorize
		.get (req, res, next)->
			res.send 'course:conference:index > '+JSON.stringify req.params
