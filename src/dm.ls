module.exports = exports = (app)->
	app
		..route '/:type(admin|teacher)?/:course/dm/:thread?'
		.get (req, res, next)->
			res.send 'direct messaging:index > '+JSON.stringify req.params