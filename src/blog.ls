module.exports = (app)->
	winston = app.locals.winston
	models = app.locals.models
	app
		..route '/:course/blog/:id?'
		.all app.locals.authorize
		.get (req, res, next)->
			err,result <- models.Course.find { 'id':req.params.course, 'school':app.locals.school }
			if err?
				winston.error err
			if !result[0]?
				next new Error 'NOT FOUND'
			else
				res.send result[0].blog

		..route '/:course/blog/:id?/edit'
		.all (req, res, next)->
			res.locals.needs = 2
			app.locals.authorize req res next
		.get (req, res, next)->
			res.send 'course:blog:edit > '+JSON.stringify req.params
