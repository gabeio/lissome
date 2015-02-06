module.exports = exports = (app)->
	app
		..route '/logout'
		.all (req, res, next)->
			err <- req.session.destroy
			res.redirect '/'
