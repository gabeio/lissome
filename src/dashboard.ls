module.exports = (app)->
	require! {
		'lodash'
	}
	_ = lodash
	app
		..route '/:index(index|dash|dashboard)?'
		.all app.locals.authorize
		.get (req, res, next)->
			res.render 'dashboard'

		..route '/preferences'
		.all app.locals.authorize
		.get (req, res, next)->
			res.send 'preferences > '+JSON.stringify req.params
