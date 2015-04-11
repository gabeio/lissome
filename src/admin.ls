require! {
	"express"
	"mongoose"
}
app = express.Router()
app
	..use (req, res, next)->
		res.locals.needs = 3
		next!
	.all (req, res, next)->
		if res.locals.auth? and res.locals.needs? and res.locals.needs <= res.locals.auth
			next!
		else
			next new Error "UNAUTHORIZED"
	..route "/admin"
	..route "/admin/:course/edit"
	.get (req, res, next)->
		err, course <- models.Course.find {
			"id":req.params.course
			"school":app.locals.school
		}
		res.send course
	..route "/admin/:course/:index(index|dash|dashboard)?"
	..route "/admin/:course/blog/:id?/edit"
	..route "/admin/:course/blog/:id?"

module.exports = app
