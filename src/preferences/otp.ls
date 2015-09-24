require! {
	"express"
	"crypto"
	"mongoose"
	"passcode"
	"thirty-two"
	"winston"
	"../app"
}
User = mongoose.models.User
router = express.Router!
router
	..route "/"
	.get (req, res, next)->
		bytes = ""
		if !res.locals.user.otp? or !res.locals.user.otp.secret? or res.locals.user.otp.secret is ""
			bytes = crypto.randomBytes 128 .toString!
			bytes = thirty-two.encode bytes .toString!slice 0,16
			req.session.preferences = {
				otp:
					secret: bytes
			}
			res.render "preferences/otp", { otp:"enable", user: res.locals.user, bytes: bytes, csrf: req.csrfToken! }
		else
			res.render "preferences/otp", { otp:"disable", csrf: req.csrfToken! }

	..route "/enable"
	.put (req, res, next)->
		var error
		/* istanbul ignore next */
		try
			res.locals.check = passcode.totp.verify {
				secret: req.session.preferences.otp.secret
				token: req.body.token
				encoding: "base32"
			}
		catch error
			winston.error error
		if res.locals.check? and res.locals.check.delta?
			res.locals.user.otp.secret = req.session.preferences.otp.secret.toString!
			res.locals.user.markModified "otp.secret"
			error, user <- res.locals.user.save!
			/* istanbul ignore if db error catcher */
			if error
				winston.error error
				next new Error "MONGO"
			else
				res.redirect "/preferences/otp?success=yes"
		else
			res.redirect "/preferences/otp?success=no"

	..route "/disable"
	.put (req, res, next)->
		var error
		/* istanbul ignore next */
		try
			res.locals.check = passcode.totp.verify {
				secret: res.locals.user.otp.secret
				token: req.body.token
				encoding: "base32"
			}
		catch error
			winston.error error
		if res.locals.check? and res.locals.check.delta?
			res.locals.user.set "otp.secret",""
			res.locals.user.otp.set "secret","changed"
			error, user <- res.locals.user.save!
			/* istanbul ignore if db error catcher */
			if error
				winston.error error
				next new Error "MONGO"
			else
				res.redirect "/preferences/otp?success=yes"
		else
			res.redirect "/preferences/otp?success=no"

module.exports = router
