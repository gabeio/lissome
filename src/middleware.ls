require! {
	"express"
	"async"
	"mongoose"
	"winston"
	"./app"
}
User = mongoose.models.User
router = express.Router!
router
# CUSTOM MIDDLEWARE
	.use (req, res, next)->
		err <- async.parallel [
			(para)->
				if req.session? and req.session.uid?
					res.locals.uid = req.session.uid.toString!
					res.locals.firstName = req.session.firstName
					res.locals.lastName = req.session.lastName
					res.locals.username = req.session.username
					res.locals.middleName? = req.session.middleName
					para!
				else
					para!
			(para)->
				if req.session? and req.session.auth?
					res.locals.auth = req.session.auth
					para!
				else
					para!
			(para)->
				/* istanbul ignore if which only tests if redis is offline */
				if !req.session?
					para "Sessions are offline."
				else
					para!
		]
		if err?
			next new Error err
		else
			next!
	.use (req, res, next)->
		err <- async.parallel [
			(done)->
				if req.session? and req.session.auth?
					# user with auth asyncly check their credentials
					err, user <- User.find {
						_id: req.session.uid
					}
					if !user? or user.length is 0
						done "LOGOUT"
					else
						done err, user
				else
					done null
		]
		if err?
			switch err
			| "LOGOUT"
				winston.warn "Killing old user session", req.session
				err <- req.session.destroy
			| _
				next new Error err
		else
			next!

module.exports = router
