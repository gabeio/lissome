module.exports = (app)->
	app
		..route '/:course/grades'
		.all (req, res, next)->
			res.locals.needs = 1
			app.locals.authorize req, res, next
		.get (req, res, next)->
			res.render 'grades'
