module.exports = (app)->
	require! {
		'lodash'
	}
	_ = lodash
	app
		..route '/:index(index|dash|dashboard)?'
		.all app.locals.authorize
		.get (req, res, next)->
			res.send """index > """+JSON.stringify(req.params)+"""<br/>
			more > """+JSON.stringify(_.omit(req.session,'cookie'))
			res.end!

		..route '/preferences'
		.all app.locals.authorize
		.get (req, res, next)->
			res.send 'preferences > '+JSON.stringify req.params
