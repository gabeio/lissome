module.exports = do ->
	require! {
		express
	}
	app = express.Router!
	app
		..route '/login'
		.get (req, res, next)->
			# res.send 'base:login > '+JSON.stringify req.params
			res.render 'login'
		.post (req, res, next)->
			
			# res.send 'base:login > '+JSON.stringify req.params

		..route '/:type(admin|teacher)?/:index(index|dash|dashboard)?'
		.get (req, res, next)->
			req.app.locals.winston.info 'test'
			res.send 'base:index > '+JSON.stringify req.params

		..route '/:type(admin|teacher)?/preferences'
		.get (req, res, next)->
			res.send 'base:preferences > '+JSON.stringify req.params

		..use '/', require './course'
