require! {
	"express"
	"async"
	"mongoose"
	"winston"
	"../app"
}
ObjectId = mongoose.Types.ObjectId
Course = mongoose.models.Course
Assignment = mongoose.models.Assignment
Attempt = mongoose.models.Attempt
router = express.Router!
router
	..route "/:course/grades"
	.all (req, res, next)->
		res.locals.needs = 1
		app.locals.authorize req, res, next
	.all (req,res,next)->
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
			next new Error "UNAUTHORIZED"
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
	.all (req, res, next)->
		err, result <- Attempt.find {
			course: ObjectId res.locals.course._id
			author: ObjectId res.locals.uid
		}
		.populate "assignment"
		.populate "author"
		.sort!
		.exec
		/* istanbul ignore if should only occur if db crashes */
		if err?
			winston.error "assign findOne conf", err
			next new Error "INTERNAL"
		else
			res.locals.attempts = result
			next!
	.all (req, res, next)->
		res.locals.average = {
			"points":0
			"total":0
		}
		async.waterfall [
			(water)->
				for grade in res.locals.attempts
					if grade.points?
						res.locals.average.points += grade.points
						res.locals.average.total += grade.assignment.totalPoints
				water null
			(water)->
				next!
				water null
		]
	.get (req, res, next)->
		res.render "course/grades"

module.exports = router
