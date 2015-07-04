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
	..route "/:course" # query :: action(new|edit|delete|grade)
	.all (req, res, next)->
		console.log "/:course"
		res.locals.needs = 1
		app.locals.authorize req, res, next
	.all (req, res, next)->
		res.locals.course = {
			"id": req.params.course
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
		/* istanbul ignore if should only occur if db crashes */
		if err
			winston.error "course findOne conf", err
			next new Error "INTERNAL"
		else
			if !result? or result.length is 0
				next new Error "NOT FOUND"
			else
				res.locals.course = result
				next!
	..use "/", require("./course/assignments")
	..use "/", require("./course/blog")
	..use "/", require("./course/conference")
	..use "/", require("./course/grades")
	..use "/", require("./course/roster")
	..use "/", require("./course/settings")
	..use "/", require("./course/index")

module.exports = router
