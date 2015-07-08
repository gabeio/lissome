require! {
	"express"
	"async"
	"lodash"
	"mongoose"
	"winston"
	"./app"
}
ObjectId = mongoose.Types.ObjectId
_ = lodash
Semester = mongoose.models.Semester
Course = mongoose.models.Course
router = express.Router!
router
	..route "/"
	.all (req, res, next)->
		res.locals.needs = 1
		app.locals.authorize req, res, next
	.get (req, res, next)->
		err, semesters <- Semester.find {
			"open":{
				"$lt": new Date Date.now!
			}
			"close":{
				"$gt": new Date Date.now!
			}
		}
		.lean!
		.exec
		res.locals.semesters = _.map _.toArray(_.pluck semesters, "_id" ), (doc)->
			doc.toString!
		<- async.parallel [
			(done)->
				if res.locals.auth >= 3
					res.locals.query = {
						"school": app.locals.school
					}
					done!
				else
					done!
			(done)->
				if res.locals.auth is 2
					res.locals.query = {
						"school": app.locals.school
						"faculty": ObjectId res.locals.uid
						# "semester": {
						# 	"$in": res.locals.semesters
						# }
					}
					done!
				else
					done!
			(done)->
				if res.locals.auth is 1
					res.locals.query = {
						"school": app.locals.school
						"students": ObjectId res.locals.uid
						"semester": {
							"$in": res.locals.semesters
						}
					}
					done!
				else
					done!
		]
		err, courses <- Course.find res.locals.query
		.lean!
		.populate {
			path: "semester"
			lean: true
		}
		.exec
		/* istanbul ignore if */
		if err
			winston.error "dashboard.ls:Course:find", err
			para "MONGO"
		else
			res.locals.courses = courses
			thisSemester = (doc)->
				if doc.semester._id.toString! in res.locals.semesters
					doc
			if res.locals.auth <= 2
				res.locals.courses = _.filter courses, thisSemester
				res.locals.otherCourses = _.reject courses, thisSemester
			else
				res.locals.courses = courses
			res.render "dashboard"


module.exports = router
