require! {
	"express"
	"async"
	"bcrypt"
	"mongoose"
	"winston"
	"../app"
}
User = mongoose.models.User
router = express.Router!
router
	..route "/"
	.get (req, res, next)->
		if req.query.success?
			res.render "preferences/password", { success:req.query.success, csrf: req.csrfToken! }
		else
			res.render "preferences/password", { csrf: req.csrfToken! }

	..route "/change"
	.put (req, res, next)->
		err <- async.waterfall [
			(done)->
				if req.body.newpass != req.body.newpass2
					res.redirect "/preferences/password?success=false"
					done "fin"
				else
					done!
			(done)->
				err,result <- bcrypt.compare req.body.oldpass, res.locals.user.hash
				done err,result
			(result,done)->
				if !result? or result is false
					res.redirect "/preferences/password?success=false"
					done "fin"
				else
					done!
			(done)->
				# user password matches
				err, hash <- bcrypt.hash req.body.newpass2, 10
				done err, hash
			(hash,done)->
				res.locals.user.hash = hash
				res.locals.user.markModified "hash"
				err,user <- res.locals.user.save
				if err
					done err
				else
					res.redirect "/preferences/password?success=true"
		]
		if err
			switch err
			| "fin"
				break
			| _
				winston.error err
				res.redirect "/preferences/password?success=false"

module.exports = router
