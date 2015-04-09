module.exports = (app)->
	require! {
		"winston"
	}
	app
		..locals.authorize = (req, res, next)->
			if res.locals.auth? and res.locals.needs? and res.locals.needs <= res.locals.auth
				next!
			else
				next new Error "UNAUTHORIZED" # other unauth
