require! {
	"express"
	"async"
	"lodash"
	"moment"
	"mongoose"
	"util"
	"winston"
	"./app"
}
ObjectId = mongoose.Types.ObjectId
User = mongoose.models.User
Course = mongoose.models.Course
Assignment = mongoose.models.Assignment
Attempt = mongoose.models.Attempt
router = express.Router!
router
	..use (req, res, next)->
		res.locals.needs = 1
		app.locals.authorize req, res, next
	..route "/:course/:anything(*)?"
	.all (req, res, next)->
		res.locals.course = {
			"_id": req.params.course
			"school": app.locals.school
		}
		/* istanbul ignore else there should be no way to hit that. */
		if res.locals.auth >= 3
			next!
		else if res.locals.auth is 2
			res.locals.course.faculty = ObjectId res.locals.uid
			next!
		else if res.locals.auth is 1
			res.locals.course.students = ObjectId res.locals.uid
			next!
		else
			next "UNAUTHORIZED"
	.all (req, res, next)->
		err, result <- Course.findOne res.locals.course
		.populate "students"
		.populate "faculty"
		.exec
		/* istanbul ignore if should only occur if db crashes */
		if err
			winston.error "course findOne conf", err
			next new Error "INTERNAL"
		else
			if !result? or result.length is 0
				winston.info req.params.course
				next new Error "NOT FOUND"
			else
				res.locals.course = result
				next "route"
	..use "/:course/assignments", require("./course/assignments")
	..use "/:course/blog", require("./course/blog")
	..use "/:course/conference", require("./course/conference")
	..use "/:course/grades", require("./course/grades")
	..use "/:course/roster", require("./course/roster")
	..use "/:course/settings", require("./course/settings")
	..use "/:course", require("./course/index")

module.exports = router
