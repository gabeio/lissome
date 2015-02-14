module.exports = (app)->
	winston = app.locals.winston
	models = app.locals.models
	app
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
		..route '/:course/:index(index|dash|dashboard)?'
		.all (req, res, next)->
			res.locals.needs = 1
			app.locals.authorize req, res, next
		.get (req, res, next)->
			err,result <- models.Course.find { 'uid':req.params.course, 'school':app.locals.school }
			if err?
				winston.error err
			if !result? or result.length is 0
				next new Error 'NOT FOUND'
			else
				res.send result.0
