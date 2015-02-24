module.exports = (app)->
	app
		..route '/:course/assignments/:action(submit)?/:unique?/:version?'
		.all (req, res, next)->
			res.locals.needs = 1
			app.locals.authorize req, res, next
		.get (req, res, next)->
			res.render 'assignments'

		..route '/:course/assignments/:action(new|edit|delete|grade)?/:unique?/:version?'
		.all (req, res, next)->
			res.locals.needs = 2
			app.locals.authorize req, res, next
		.get (req, res, next)->
			res.render 'assignments'
