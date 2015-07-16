require! {
	"express"
	"bcrypt"
	"mongoose"
	"passcode"
	"thirty-two"
	"winston"
	"./app"
}
User = mongoose.models.User
router = express.Router!
router
	..route "/"
	.all (req, res, next)->
		if !res.session.opt? # redirects if logged in/not half logged in
			res.redirect "/"
		else
			next!
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
				winston.err "user:find", err
			if !user? or user.length is 0
				res.render "login", { error: "user not found", csrf: req.csrfToken! }
			else
				if user.otp? && !user.opt.count? # user has otp but no count it's totp
					if passcode.totp.verify({ secret: user.totp, token: thirty-two.decode(req.body.token) }) is 0
						req.session.auth = user.type
						res.redirect "/"
					else
						res.render "login", { error:"bad login credentials", csrf: req.csrfToken! }
				else if user.otp? && user.otp.count? # user has otp and count it's hotp
					if passcode.hotp.verify({ secret: user.hotp, token: thirty-two.decode(req.body.token), counter: user.hotpCount }) is 0
						user.hotpCount += 1
						err, user <- user.save
						req.session.auth = user.type
						res.redirect "/"
					else
						res.render "login", { error:"bad login credentials", csrf: req.csrfToken! }
				else
					winston.err "otp.ls: (else statement) should not have gotten here"
					next new Error "UNKNOWN"
		else
			res.render "login", { error: "bad login credentials", csrf: req.csrfToken!  }

module.exports = router
