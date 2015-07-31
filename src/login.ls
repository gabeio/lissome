require! {
	"express"
	"scrypt"
	"mongoose"
	"winston"
	"./app"
}
var asdf
parser = app.locals.multer.fields []
User = mongoose.models.User
router = express.Router!
router
	..route "/"
	.all (req, res, next)->
		if req.session.opt? # first check otp so we don't cause redirect loop
			res.redirect "/otp"
		else if res.locals.auth? # then check if user is logged in
			res.redirect "/"
		else
			next!
	.get (req, res, next)->
		res.render "login", { csrf: req.csrfToken! }
	.post parser, (req, res, next)->
		if !req.body.username? or req.body.username is "" or !req.body.password? or req.body.password is ""
			res.render "login", { error: "bad login credentials", csrf: req.csrfToken!  }
		else
			err, user <- User.findOne {
				"username": req.body.username.toLowerCase!
				"school": app.locals.school
			}
			/* istanbul ignore if */
			if err
				winston.error "user:find", err
				next new Error err
			else
				if !user? or user.length is 0
					res.render "login", { error: "user not found", csrf: req.csrfToken! }
				else
					scrypt.verify.config.hashEncoding = "base64"
					error,result <- scrypt.verify user.hash, new Buffer(req.body.password)
					/* istanbul ignore if */
					if error? and error.scrypt_err_message is "password is incorrect"
						res.render "login", { error:"bad login credentials", csrf: req.csrfToken! }
					else if error?
						# bad password
						winston.error error
						next new Error error
					else
						if result isnt true
							res.render "login", { error:"bad login credentials", csrf: req.csrfToken! }
						else
							# do NOT take anything from req.body
							if user.otp? and user.otp.secret? and user.otp.secret.length isnt 0 # if otp and secret
								req.session.otp = user.otp.secret
							else # otherwise
								req.session.auth = user.type # give them their auth
							req.session.username = user.username
							req.session.userid = user.id
							req.session.uid = user._id
							req.session.firstName = user.firstName
							/* istanbul ignore next */
							req.session.middleName? = user.middleName
							req.session.lastName = user.lastName
							if user.otp? and user.otp.secret? and user.otp.secret.length isnt 0
								res.redirect "/otp"
							else
								res.redirect "/"

module.exports = router
