require! {
	"express"
	"async"
	"mongoose"
	"winston"
	"../app"
}
ObjectId = mongoose.Types.ObjectId
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
		.sort { timestamp: -1 }
		.exec
		/* istanbul ignore if db error catcher */
		if err?
			winston.error "grades find", err
			next new Error "INTERNAL"
		else
			res.locals.attempts = result
			next!
	.all (req, res, next)->
		res.locals.average = {
			"points":0
			"total":0
		}
		res.locals.assignPoints = {}
		async.waterfall [
			(water)->
				for grade in res.locals.attempts
					# is this attempt graded?
					if grade.points?
						# if so
						# did we come across another attempt on the same assignment?
						if res.locals.assignPoints[grade.assignment.id]?
							# if we did
							# did we come across another attempt does this have a better grade?
							if res.locals.assignPoints[grade.assignment.id].points <= grade.points
								# if it is replace it with this attempt
								res.locals.assignPoints[grade.assignment.id].points = grade.points
						else
							# if we didn't
							# add it to the assignments' averages
							res.locals.assignPoints[grade.assignment.id] = {}
							res.locals.assignPoints[grade.assignment.id].points = grade.points
							res.locals.assignPoints[grade.assignment.id].total = grade.assignment.totalPoints
				water null
			(water)->
				# now actually average THE BEST, only *one*, attempt per assignment
				for k,v of res.locals.assignPoints
					res.locals.average.points += v.points
					res.locals.average.total += v.total
				water null
			(water)->
				# then run the average points/total
				res.locals.average.ave = res.locals.average.points / res.locals.average.total
				# *100 since we want it out of 100 not 1
				res.locals.average.ave *= 100
				# if the average was 0/0 (nothing attempted/assigned) then the "average" should be 100%!
				if res.locals.average.ave === NaN then res.locals.average.ave = 100
				water null
		]
		next!
	.all (req, res, next)->
		res.locals.assignmentattempts = {}
		for attempt in res.locals.attempts
			if !res.locals.assignmentattempts[attempt.assignment._id]?
				res.locals.assignmentattempts[attempt.assignment._id] = []
			res.locals.assignmentattempts[attempt.assignment._id].push(attempt)
		next!
	.get (req, res, next)->
		res.render "course/grades"

module.exports = router
/* istanbul ignore next (not my function to cover) */
