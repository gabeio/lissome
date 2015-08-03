require! {
	"express"
	"mongoose"
	"passcode"
	"winston"
	"./app"
}
User = mongoose.models.User
router = express.Router!
router
	..route "/"
	.all (req, res, next)->
		if req.session.otp? # redirects if logged in/not half logged in
			next!
		else
			res.redirect "/"
	.get (req, res, next)->
		res.render "otp", { csrf: req.csrfToken! }
	.post (req, res, next)->
		if req.body.token? and req.body.token isnt ""
			err, user <- User.findOne {
				"_id": res.locals.uid.toLowerCase!
				"school": app.locals.school
			}
			/* istanbul ignore if */
			if err
				winston.error "user:find", err
				next new Error "MONGO"
			if !user? or user.length is 0
				# user not found
				err <- session.destroy
				winston.error err if err
				res.redirect "/"
				# res.render "login", { error: "user not found", csrf: req.csrfToken! }
			else
				if user.otp? and user.otp.secret? and user.otp.secret.length isnt 0
					res.locals.verify = passcode.totp.verify {
						secret: user.otp.secret
						token: req.body.token
						encoding: "base32"
					}
					if res.locals.verify? and res.locals.verify.delta?
						delete req.session.otp
						req.session.auth = user.type
						res.redirect "/"
					else
						err <- req.session.destroy
						if err? then winston.error err
						res.redirect "/login"
				else
					winston.error "otp.ls: (else statement) probably old session; destroying session..."
					err <- session.destroy
					winston.error err if err
					res.redirect "/"
		else
			res.status 400 .render "otp", { error: "missing field", csrf: req.csrfToken!  }

module.exports = router
