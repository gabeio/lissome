require! {
	"express"
	"mongoose"
	"async"
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
		err <- async.waterfall [
			(done)->
				if !req.body.token? or req.body.token is ""
					res.status 400 .render "otp", { error: "missing field", csrf: req.csrfToken! }
					done "fin"
				else
					done!
			(done)->
				err, user <- User.findOne {
					"_id": res.locals.uid.toLowerCase!
					"school": app.locals.school
				}
				done err, user
			(user,done)->
				if !user? or user.length is 0
					# user not found
					err <- req.session.destroy
					winston.error "otp.ls: ", err if err
					res.redirect "/"
					done "fin"
				else
					done null, user
			(user,done)->
				if !user.otp? or !user.otp.secret? or user.otp.secret.length isnt 0
					res.locals.verify = passcode.totp.verify {
						secret: user.otp.secret
						token: req.body.token
						encoding: "base32"
					}
					if res.locals.verify? and res.locals.verify.delta?
						delete req.session.otp
						req.session.auth = user.type
						res.redirect "/"
						done "fin"
					else
						err <- req.session.destroy
						winston.error "otp.ls: ", err if err
						res.redirect "/login"
						done "fin"
				else
					winston.warn "otp.ls: (else statement) probably old session; destroying session..."
					err <- session.destroy
					winston.error "otp.ls: ", err if err
					res.redirect "/"
					done "fin"
		]
		if err?
			switch err
			| "fin"
				break
			| _
				# winston.error "otp.ls: ", err
				next new Error err

module.exports = router
