require! {
	"express"
	"bcrypt"
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
				"username": res.locals.username.toLowerCase!
				"school": app.locals.school
			}
			/* istanbul ignore if */
			if err
				winston.error "user:find", err
			if !user? or user.length is 0
				res.render "login", { error: "user not found", csrf: req.csrfToken! }
			else
				if user.otp? && user.otp.secret? && !user.otp.count? # user has otp but no count it's totp
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
						res.redirect "/"
				else if user.otp? && user.otp.secret? && user.otp.count? # user has otp and count it's hotp
					res.locals.verify = passcode.hotp.verify {
						secret: user.otp.secret
						token: req.body.token
						counter: user.otp.count
						encoding: "base32"
					}
					if res.locals.verify? and res.locals.verify.delta?
						user.otp.count += 1
						user.otp.set("count","changed")
						err, user <- user.save
						if err then winston.error err
						delete req.session.otp
						req.session.auth = user.type
						res.redirect "/"
					else
						err <- req.session.destroy
						if err? then winston.error err
						res.redirect "/"
				else
					winston.error "otp.ls: (else statement) probably old session; destroying session..."
					err <- req.session.destroy
					res.redirect "/"
		else
			res.render "otp", { error: "missing field", csrf: req.csrfToken!  }

module.exports = router
