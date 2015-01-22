module.exports = exports = (app)->
	app
		..route '/:type(admin|teacher)?/:course/:index(index|dash|dashboard)?'
		.get (req, res, next)->
			res.send 'course:index > '+JSON.stringify req.params

		..route '/:type(admin|teacher)/:course/edit'
		.get (req, res, next)->
			# if app.req.locals.isTeacher(req) or app.req.locals.isAdmin(req)
			res.send 'course:edit > '+JSON.stringify req.params
			# res.status 500 .send 'Forbidden'

		..use '/', require './assignments' # hw/projects/other
		..use '/', require './examinations' # exams/tests/quizes/etc
		..use '/', require './conference' # community chat
		..use '/', require './dm' # direct to teacher/student
		..use '/', require './blog' # updates/rants/etc
