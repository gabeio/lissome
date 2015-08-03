require! {
	"express"
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
		if !req.body.pin? \ # if no pin
			or req.body.pin is "" \ # if pin is blank
			or !(req.body.pin >= 0) # if pin isn't positive number
			res.status 400 .render "pin", { error: true , csrf: req.csrfToken!  }
		else
			# check pin against req.body.pin
			if praseInt(req.session.pin) is parseInt(req.body.pin)
				delete req.session.pin
				req.session.auth = user.type
				res.redirect "/"
			else
				err <- req.session.destroy
				if err? then winston.error err
				res.redirect "/login"

module.exports = router
