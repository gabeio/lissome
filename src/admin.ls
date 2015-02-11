module.exports = (app)->
	models = app.locals.models
	app.use (req, res, next)->
		res.locals.needs = 3
		app.locals.authorize req, res, next
	app
		..route '/admin'
		..route '/admin/:subject?/:course/edit'
		.get (req, res, next)->
			err, course <- models.Course.find {
				'subject':req.params.subject
				'id':req.params.course
				'school':app.locals.school
			}
			res.send course
		..route '/admin/:subject?/:course/:index(index|dash|dashboard)?'
		..route '/admin/:subject?/:course/blog/:id?/edit'
		..route '/admin/:subject?/:course/blog/:id?'
