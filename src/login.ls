require! {
	"express"
	"mongoose"
	"crypto"
	"scrypt"
	"request"
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
		else if req.session.pin?
			res.redirect "/pin"
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
					if error? and error.scrypt_err_message is "password is incorrect"
						res.render "login", { error:"bad login credentials", csrf: req.csrfToken! }
					else if error?
						# unknown scrypt error
						winston.error error
						next new Error error
					else
						if result isnt true
							res.render "login", { error:"bad login credentials", csrf: req.csrfToken! }
						else
							# do NOT take anything from req.body
							if user.otp.secret.length isnt 0 # if otp and secret
								req.session.otp = user.otp.secret
							else if user.pin.required is true # if user requires push-pin
								# 1. generate pushpin
								pin = ""
								while pin.length < 8
									byte = crypto.randomBytes 1 .toString!
									if parseInt(byte) >= 0
										pin += byte
								# 2. push pin to user
								if user.pin.method is "pushover"
									if typeof app.locals.pushover.token isnt "undefined"
										err, response, body <- request {
											uri: "https://api.pushover.net/1/messages.json"
											method: "POST"
											form: {
												token: app.locals.pushover.token
												message: "Your pin is #{pin}. If you got this message and were not logging in change your password!"
												user: user.pin.token
											}
										}
										winston.info body if response.statusCode isnt 200
										winston.error err if err
									#else
										# pretend we sent the pin
								else if user.pin.method is "pushbullet"
									if typeof app.locals.pushbullet.token isnt "undefined"
										err, response, body <- request {
											uri: "https://api.pushbullet.com/v2/pushes"
											method: "POST"
											headers: {
												"Authorization": "Bearer #{app.locals.pushbullet.token}"
											}
											form: {
												email: user.pin.token
												type: "note"
												body: "Your pin is #{pin}. If you got this message and were not logging in change your password!"
											}
										}
										winston.info body if response.statusCode isnt 200
										winston.error err if err
									#else
										# pretend we sent the pin
								else
									winston.error "login.ls: {{ user.username }} probably just got locked out. {{ user.pin.method }}"
									next new Error "Locked Out"
								# 3. add pushpin to session
								req.session.pin = pin
							else # otherwise
								req.session.auth = user.type # give them their auth
							req.session.username = user.username
							req.session.userid = user.id
							req.session.uid = user._id
							req.session.firstName = user.firstName
							req.session.middleName? = user.middleName
							req.session.lastName = user.lastName
							if user.otp.secret.length isnt 0
								res.redirect "/otp"
							else if req.session.pin?
								res.redirect "/pin"
							else
								res.redirect "/"

module.exports = router
