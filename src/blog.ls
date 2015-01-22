module.exports = exports = (app)->
	app
		..route '/:type(admin|teacher|student)?/:course/blog/:id?'
		.get (req, res, next)->
			res.send 'blog:index > '+JSON.stringify req.params

		..route '/:type(admin|teacher|student)/:course/blog/edit'
		.get (req, res, next)->
			res.send 'blog:edit > '+JSON.stringify req.params
