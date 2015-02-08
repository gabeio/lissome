module.exports = (app)->
	app
		..route '/:course/blog/:id?'
		.all app.locals.authorize
		.get (req, res, next)->
			res.send 'course:blog:index > '+JSON.stringify req.params

		..route '/:course/blog/:id?/edit'
		.all (req, res, next)->
			res.locals.needs = 2
			app.locals.authorize req res next
		.get (req, res, next)->
			res.send 'course:blog:edit > '+JSON.stringify req.params
