require! {
	"express"
	"async"
	"mongoose"
	"winston"
	"./app"
}
User = mongoose.models.User
router = express.Router!
router
	..route "/"
	.all (req, res, next)->
		if req.session.pin? # redirects if logged in/not half logged in
			next!
		else
			res.redirect "/"
	.get (req, res, next)->
		res.render "pin", { csrf: req.csrfToken! }
	.post (req, res, next)->
		err <- async.waterfall [
			(done)->
				if !req.body.pin? or req.body.pin is ""
					res.status 400 .render "pin", { error: true , csrf: req.csrfToken! }
					done "fin"
				else
					done null
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
					winston.error err if err
					res.redirect "/"
					done "fin"
				else
					done null, user
			(user,done)->
				# check pin against req.body.pin
				if req.session.pin.toString! is req.body.pin.toString!
					delete req.session.pin
					req.session.auth = user.type
					res.redirect "/"
					done null
				else
					err <- req.session.destroy
					if err? then winston.error err
					res.redirect "/login"
					done null
		]
		if err?
			switch err
			| "fin"
				break
			| _
				winston.error "pin.ls: ", err
				next new Error "MONGO"

module.exports = router
