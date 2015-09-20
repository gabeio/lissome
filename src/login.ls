require! {
	"express"
	"bcrypt"
	"mongoose"
	"async"
	"crypto"
	"request"
	"winston"
	"./app"
}
parser = app.locals.multer.fields []
User = mongoose.models.User
router = express.Router!
router
	..route "/"
	.all (req, res, next)->
		if req.session.otp? # first check otp so we don't cause redirect loop
			res.redirect "/bounce?to=/otp"
		else if req.session.pin?
			res.redirect "/bounce?to=/pin"
		else if res.locals.auth? # then check if user is logged in
			res.redirect "/bounce?to=/"
		else
			next!
	.get (req, res, next)->
		res.render "login", { csrf: req.csrfToken! }
	.post parser, (req, res, next)->
		err <- async.waterfall [
			(done)->
				if !req.body.username? or req.body.username is "" or !req.body.password? or req.body.password is ""
					done "bad"
				else
					done!
			(done)->
				err, user <- User.findOne {
					"username": req.body.username.toLowerCase!
					"school": app.locals.school
				}
				done err, user
			(user, done)->
				if !user? or user.length is 0
					res.render "login", { error: "user not found", csrf: req.csrfToken! }
					done "fin"
				else
					done null, user
			(user,done)->
				err,result <- bcrypt.compare req.body.password, user.hash
				/* istanbul ignore if this is probably if the library somehow has an error */
				if err
					winston.error err
					done "bad"
				else
					done err, result, user
			(result,user,done)->
				if result isnt true
					done "bad"
				else
					done null, user
			(user,done)->
				# do NOT take anything from req.body
				if user.otp.secret.length isnt 0 # if otp and secret
					req.session.otp = user.otp.secret
					done null, user
				else
					done null, user
			(user,done)->
				if user.pin.required is true # if user requires push-pin
					# 1. generate pushpin
					pin = ""
					while pin.length < 8
						byte = crypto.randomBytes 1 .toString!
						if parseInt(byte, 10) >= 0 # check if it's an "int"
							pin += byte
					# 2. push pin to user
					if user.pin.method is "pushover"
						/* istanbul ignore if */
						if typeof app.locals.pushover.token isnt "undefined"
							/* istanbul ignore next */
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
							winston.error "login.ls: request.pushover", err if err
						#else
							# pretend we sent the pin
					else if user.pin.method is "pushbullet"
						/* istanbul ignore if */
						if typeof app.locals.pushbullet.token isnt "undefined"
							/* istanbul ignore next */
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
							winston.error "login.ls: request.pushbullet", err if err
						#else
							# pretend we sent the pin
					else
						# should never get here
						winston.warn "#{user.username} Locked Out"
					# 3. add pushpin to session
					req.session.pin = pin
					done null, user
				else
					done null, user
			(user,done)->
				if !req.session.otp? and !req.session.pin?
					req.session.auth = user.type # give them their auth
					done null, user
				else
					done null, user
			(user, done)->
				req.session.username = user.username
				req.session.userid = user.id
				req.session.uid = user._id
				req.session.firstName = user.firstName
				req.session.middleName? = user.middleName
				req.session.lastName = user.lastName
				if user.otp.secret.length isnt 0
					res.redirect "/bounce?to=/otp"
					done "fin"
				else if req.session.pin?
					res.redirect "/bounce?to=/pin"
					done "fin"
				else
					res.redirect "/bounce?to=/"
					done "fin"
		]
		/* istanbul ignore else */
		if err?
			/* istanbul ignore next */
			switch err
			| "bad"
				res.render "login", { error:"bad login credentials", csrf: req.csrfToken! }
			| "fin"
				break # should have been answered
			| _
				# winston.error "login.ls: ",err
				next new Error err

module.exports = router
