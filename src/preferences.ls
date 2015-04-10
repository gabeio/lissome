require! {
	"express"
}
app = express.Router()
app
	..route "/preferences"
	.all (req, res, next)->
		res.locals.needs = 1
		next!
	.all (req, res, next)->
		if res.locals.auth? and res.locals.needs? and res.locals.needs <= res.locals.auth
			next!
		else
			next new Error "UNAUTHORIZED"
	.get (req, res, next)->
		res.render "preferences"

module.exports = app
