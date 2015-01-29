module.exports = exports = (app)->
	require! {
		express
	}
	app = express.Router!
	app
		..route '/:type(admin|teacher)?/:course/assignments/:id?/:version?'
		.get (req, res, next)->
			res.send 'assignments:index > '+JSON.stringify req.params

		..route '/:type(admin|teacher)/:course/assignments/:id?/:version?/edit'
		.get (req, res, next)->
			res.send 'assignments:edit > '+JSON.stringify req.params
