module.exports = do ->
	require! {
		express
	}
	app = express.Router!
	app
		..route '/:type(admin|teacher)?/:course/blog/:id?'
		.get (req, res, next)->
			res.send 'blog:index > '+JSON.stringify req.params

		..route '/:type(admin|teacher)/:course/blog/edit'
		.get (req, res, next)->
			res.send 'blog:edit > '+JSON.stringify req.params
