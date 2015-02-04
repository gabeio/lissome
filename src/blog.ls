module.exports = exports = (app)->
	app
		..route '/:course/blog/:id?'
		.all app.locals.authorize
		.get (req, res, next)->
			res.send 'blog:index > '+JSON.stringify req.params

		..route '/:course/blog/:id?/edit'
		.all (req, res, next)->
			res.locals.needs = "Faculty"
		.all app.locals.authorize
		.get (req, res, next)->
			res.send 'blog:edit > '+JSON.stringify req.params
