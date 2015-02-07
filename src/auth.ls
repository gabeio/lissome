module.exports = (app)->
	require! {
		'util'
	}
	winston = app.locals.winston
	app
		..locals.authorize = (req, res, next)->
			winston.info req.session.auth
			winston.info res.locals.needs
			if !req.session.auth?
				next new Error 'UNAUTHORIZED'
			else
				# req.session.auth = (1|2|3|4)
				if !res.locals.needs?
					winston.error req.originalUrl
					# throw new Error 'UNKNOWN NEEDS'
					next! # if needs is undefined then probably okay
				else # check needs <= has
					if res.locals.needs <= req.session.auth
						next!
					else
						next new Error 'UNAUTHORIZED'
