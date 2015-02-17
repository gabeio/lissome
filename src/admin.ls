module.exports = (app)->
	models = app.locals.models
	app
		..use (req, res, next)->
			res.locals.needs = 3
			app.locals.authorize req, res, next
		..route '/admin'
		..route '/admin/:course/edit'
		.get (req, res, next)->
			err, course <- models.Course.find {
				'id':req.params.course
				'school':app.locals.school
			}
			res.send course
		..route '/admin/:course/:index(index|dash|dashboard)?'
		..route '/admin/:course/blog/:id?/edit'
		..route '/admin/:course/blog/:id?'
