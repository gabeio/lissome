require! {
	"express"
	"scrypt"
	"mongoose"
	"winston"
	"../app"
}
User = mongoose.models.User
router = express.Router!
require! "util"
router
	..route "/"
	.get (req, res, next)->
		if req.query.success?
			res.render "preferences/password", { success:req.query.success }
		else
			res.render "preferences/password"

	..route "/change"
	.put (req, res, next)->
		scrypt.verify.config.hashEncoding = "base64"
		error,result <- scrypt.verify res.locals.user.hash, new Buffer(req.body.oldpass)
		if error? and error.scrypt_err_message is "password is incorrect"
			res.redirect "/preferences/password?success=false"
		else if error?
			# unknown scrypt error
			winston.error error
			next new Error error
		else if req.body.newpass != req.body.newpass2
			res.redirect "/preferences/password?success=false"
		else
			# user password matches
			scrypt.hash.config.outputEncoding = "base64"
			err, hash <- scrypt.hash new Buffer(req.body.newpass2), { N:1, r:1, p:1 }
			res.locals.user.hash = hash
			res.locals.user.markModified "hash"
			err,user <- res.locals.user.save
			if err
				winston.error "user:find", err
				next new Error err
			else
				res.redirect "/preferences/password?success=true"

module.exports = router
