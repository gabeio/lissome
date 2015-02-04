module.exports = exports = (app)->
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
				if !res.locals.needs?
					next! # if needs is undefined then probably okay
				else # check needs <= has
					switch res.locals.needs
					| 'Student'
						next! # allow student/faculty/admin
					| 'Faculty'
						if req.session.auth in ['Faculty','Admin']
							next! # allow faculty/admin
						else
							next new Error 'UNAUTHORIZED'
					| _
						if req.session.auth is 'Admin'
							next! # only admins
						else
							next new Error 'UNAUTHORIZED'
