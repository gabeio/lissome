require! {
	"express"
	"bcrypt"
	"mongoose"
	"winston"
	"./app"
}
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
		if req.body.username? and req.body.username isnt "" and req.body.password? and req.body.password isnt ""
			err, user <- User.findOne {
				"username": req.body.username.toLowerCase!
				"school": app.locals.school
			}
			/* istanbul ignore if */
			if err
				winston.error "user:find", err
			if !user? or user.length is 0
				res.render "login", { error: "user not found", csrf: req.csrfToken! }
			else
				err,result <- bcrypt.compare req.body.password, user.hash
				/* istanbul ignore if */
				if err
					winston.error err
				if result is true
					# do NOT take anything from req.body
					if user.otp? and user.otp.secret? # if otp and secret
						req.session.otp = user.otp.secret
						req.session.otp? = user.otp.count
					else # otherwise
						req.session.auth = user.type # give them their auth
					req.session.username = user.username
					req.session.userid = user.id
					req.session.uid = user._id
					req.session.firstName = user.firstName
					/* istanbul ignore next */
					req.session.middleName? = user.middleName
					req.session.lastName = user.lastName
					if user.otp? and user.otp.secret?
						res.redirect "/otp"
					else
						res.redirect "/"
				else
					res.render "login", { error:"bad login credentials", csrf: req.csrfToken! }
		else
			res.render "login", { error: "bad login credentials", csrf: req.csrfToken!  }

module.exports = router
