module.exports = do ->
	require! {
		express
	}
	app = express.Router!
	app
		..route '/:type(admin|teacher)?/:course/exams/:id?/:version?'
		.get (req, res, next)->
			res.send 'exams:index > '+JSON.stringify req.params

		..route '/:type(admin|teacher)/:course/exams/:id?/:version?/edit'
		.get (req, res, next)->
			res.send 'exams:edit > '+JSON.stringify req.params
