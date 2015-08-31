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
			res.render "preferences/otp", { otp:"enable", user: res.locals.user, bytes: bytes }
		else
			res.render "preferences/otp", { otp:"disable" }

	..route "/enable"
	.put (req, res, next)->
		res.locals.check = passcode.totp.verify {
			secret: req.session.preferences.otp.secret
			token: req.body.token
			encoding: "base32"
		}
		if res.locals.check? and res.locals.check.delta?
			res.locals.user.otp.secret = req.session.preferences.otp.secret.toString!
			res.locals.user.markModified "otp.secret"
			error, user <- res.locals.user.save!
			if error
				winston.error error
				next new Error "MONGO"
			else
				res.redirect "/preferences/otp?success=yes"
		else
			res.redirect "/preferences/otp?success=no"

	..route "/disable"
	.put (req, res, next)->
		res.locals.user.set "otp.secret",""
		res.locals.user.otp.set "secret","changed"
		err, user <- res.locals.user.save!
		if err?
			winston.error err
			next new Error "MONGO"
		else
			res.redirect "/preferences/otp?success=yes"

module.exports = router
