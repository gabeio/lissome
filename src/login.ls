require! {
	"express"
	"bcrypt"
	"mongoose"
	"winston"
	"./app"
}
User = mongoose.models.User
router = express.Router!
router
	..route "/"
	.get (req, res, next)->
		if res.locals.auth? or res.locals.userid? or res.locals.username?
			res.redirect "/"
		else
			res.render "login", { csrf: req.csrfToken! }
	.post (req, res, next)->
		if req.body.username? and req.body.username isnt "" and req.body.password? and req.body.password isnt ""
			err, user <- User.findOne {
				"username":req.body.username.toLowerCase!
				"school":app.locals.school
			}
			/* istanbul ignore if */
			if err
				winston.err "user:find", err
			if !user? or user.length is 0
				res.render "login", { error: "username not found", csrf: req.csrfToken! }
			else
				err,result <- bcrypt.compare req.body.password, user.hash
				/* istanbul ignore if */
				if err
					winston.err err
				if result is true
					# do NOT take anything from req.body
					req.session.auth = user.type
					req.session.username = user.username
					req.session.userid = user.id
					req.session.uid = user._id
					req.session.firstName = user.firstName
					/* istanbul ignore next */
					req.session.middleName? = user.middleName
					req.session.lastName = user.lastName
					res.redirect "/"
				else
					res.render "login", { error:"bad login credentials", csrf: req.csrfToken! }
		else
			res.render "login", { error: "bad login credentials", csrf: req.csrfToken!  }

module.exports = router
