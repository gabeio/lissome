module.exports = (app)->
	app
		..route "/:course/dm/:thread?"
		.all app.locals.authorize
		.get (req, res, next)->
			res.send "direct messaging:index > "+JSON.stringify req.params
