module.exports = (app)->
	require! {
		'lodash'
	}
	_ = lodash
	app
		..route '/:index(index|dash|dashboard)?'
		.all app.locals.authorize
		.get (req, res, next)->
			res.write 'index > '+JSON.stringify(req.params)+ '<br>'
			res.write '\nmore > '+JSON.stringify(_.omit(req.session,'cookie'))+ '<br>'
			res.end!

		..route '/preferences'
		.all app.locals.authorize
		.get (req, res, next)->
			res.send 'preferences > '+JSON.stringify req.params
