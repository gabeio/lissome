module.exports = (app)->
	winston = app.locals.winston
	models = app.locals.models
	app
		..route '/:course/:index(index|dash|dashboard)?'
		.all app.locals.authorize
		.get (req, res, next)->
			err,result <- models.Course.find { 'id':req.params.course, 'school':app.locals.school }
			if err?
				winston.error err
			if !result[0]?
				next new Error 'NOT FOUND'
			else
				res.send result

		..route '/:course/edit'
		.all (req, res, next)->
			res.locals.needs = 2
			app.locals.authorize req, res, next
		.get (req, res, next)->
			res.send 'this will allow showing of course settings'
			/*
			err,result <- models.Course.find { 'id':req.params.course, 'school':app.locals.school }
			if err?
				winston.error err
			if !result[0]?
				next new Error 'NOT FOUND'
			else
				res.send result
			*/
		.post (req, res, next)->
			next new Error 'NOT IMPL'
			/*
			err,result <- models.Course.update { 'id':req.params.course, 'school':app.locals.school }, {}
			if err?
				winston.error err
			if !result[0]?
				next new Error 'NOT FOUND'
			else
				res.send result
			*/
