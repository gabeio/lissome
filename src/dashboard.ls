require! {
	"express"
}
app = express.Router()
require! {
	"async"
	"lodash"
	"mongoose"
	"winston"
}
_ = lodash
Course = mongoose.models.Course

app
	..route "/:index(index|dash|dashboard)?"
	.all (req, res, next)->
		res.locals.needs = 1
		next!
	.all (req, res, next)->
		if res.locals.auth? and res.locals.needs? and res.locals.needs <= res.locals.auth
			next!
		else
			next new Error "UNAUTHORIZED"
	.get (req, res, next)->
		<- async.parallel [
			(done)->
				if res.locals.auth is 3
					err, courses <- Course.find {
						"school":app.locals.school
					}
					/* istanbul ignore if */
					if err
						winston.error "course:find", err
						next new Error "INTERNAL"
					else
						res.locals.courses = courses
						done!
				else
					done!
			(done)->
				if res.locals.auth is 2
					err, courses <- Course.find {
						"school":app.locals.school
						"faculty":mongoose.Types.ObjectId(res.locals.uid)
					}
					/* istanbul ignore if */
					if err
						winston.error "course:find", err
						next new Error "INTERNAL"
					else
						res.locals.courses = courses
						done!
				else
					done!
			(done)->
				if res.locals.auth is 1
					err, courses <- Course.find {
						"school":app.locals.school
						"students":mongoose.Types.ObjectId(res.locals.uid)
					}
					/* istanbul ignore if */
					if err
						winston.error "course:find", err
						next new Error "INTERNAL"
					else
						res.locals.courses = courses
						done!
				else
					done!
		]
		res.render "dashboard"

module.exports = app
