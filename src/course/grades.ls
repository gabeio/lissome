require! {
	"express"
	"async"
	"mongoose"
	"winston"
	"../app"
}
ObjectId = mongoose.Types.ObjectId
Assignment = mongoose.models.Assignment
Attempt = mongoose.models.Attempt
router = express.Router!
router
	..route "/"
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
				res.locals.average.ave = res.locals.average.points / res.locals.average.total
				res.locals.average.ave *= 100
				if res.locals.average.ave === NaN
					res.locals.average.ave = 100
				next!
				water null
		]
	.get (req, res, next)->
		res.render "course/grades"

module.exports = router
