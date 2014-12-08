module.exports = do ->
	require! {
		express
	}
	app = express.Router!
	app
		..route '/:type(admin|teacher)?/:course/pm/:id?'
		.get (req, res, next)->
			res.send 'private messaging:index > '+JSON.stringify req.params
