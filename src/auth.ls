module.exports = (app)->
	require! {
		'util'
	}
	winston = app.locals.winston
	app
		..locals.authorize = (req, res, next)->
			winston.info "auth #{req.session.auth}"
			winston.info "needs #{res.locals.needs}"
			if !req.session.auth?
				next new Error 'UNAUTHORIZED'
			else
				# req.session.auth = (1|2|3|4)
				if !res.locals.needs?
					winston.error '!needs? '+req.originalUrl
					# throw new Error 'UNKNOWN NEEDS'
					next! # if needs is undefined then probably okay
				else # check needs <= has
					if req.session.auth is 3
						next! # just get admins through
					else if res.locals.needs <= req.session.auth
						if req.params.course in req.session.courses # check if student/teacher part of class
							next!
						else
							next new Error 'UNAUTHORIZED'
					else
						next new Error 'UNAUTHORIZED' # other unauth
