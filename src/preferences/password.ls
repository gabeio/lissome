require! {
	"express"
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
			res.render "preferences/password", { success:req.query.success }
		else
			res.render "preferences/password"

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
				error,result <- bcrypt.compare res.locals.user.hash, new Buffer(req.body.oldpass)
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
