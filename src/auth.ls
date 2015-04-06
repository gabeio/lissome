module.exports = (app)->
	require! {
		'winston'
	}
	app
		..locals.authorize = (req, res, next)->
			if !res.locals.auth?
				next new Error 'UNAUTHORIZED'
			else
				# req.session.auth = (1|2|3)
				/* istanbul ignore if it only should happen in development */
				if !res.locals.needs?
					winston.error "!needs? #{req.originalUrl}"
					# next new Error 'UNKNOWN NEEDS'
					next! # if needs is undefined then probably okay
				else # check needs <= has
					if res.locals.needs <= res.locals.auth
						next!
					else
						next new Error 'UNAUTHORIZED' # other unauth
