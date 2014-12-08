module.exports = do ->
	require! {
		express
	}
	app = express.Router!
	app
		..route '/:type(admin|teacher)?/:course/conference/:thread?'
		.get (req, res, next)->
			res.send 'conference:index > '+JSON.stringify req.params
