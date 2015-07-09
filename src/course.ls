require! {
	"express"
	"async"
	"lodash"
	"mongoose"
	"winston"
	"util"
	"./app"
}
ObjectId = mongoose.Types.ObjectId
_ = lodash
Semester = mongoose.models.Semester
Course = mongoose.models.Course
router = express.Router!
router
	..route "/:course/:anything(*)?"
	.all (req, res, next)->
		res.locals.needs = 1
		app.locals.authorize req, res, next
	.all (req, res, next)->
		res.locals.course = {
			"_id": req.params.course
			"school": app.locals.school
		}
		err <- async.parallel [
			(para)->
				if res.locals.auth >= 3
					para!
				else
					para!
			(para)->
				if res.locals.auth is 2
					res.locals.course.faculty = ObjectId res.locals.uid
					para!
				else
					para!
			(para)->
				if res.locals.auth is 1
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
					if err
						winston.error "course.ls:Semester:find", err
						para "MONGO"
					else
						res.locals.semesters = _.pluck semesters, "_id"
						res.locals.course.students = ObjectId res.locals.uid
						res.locals.course.semester = {
							"$in": res.locals.semesters
						}
						para!
				else
					para!
			(para)->
				if !res.locals.auth? or res.locals.auth <= 0
					para "UNAUTHORIZED"
				else
					para!
		]
		if err
			next new Error err
		else
			err, result <- Course.findOne res.locals.course
			.populate "semester"
			.populate "students"
			.populate "faculty"
			.exec
			/* istanbul ignore if should only occur if db crashes */
			if err
				winston.error "course.ls:Course:findOne", err
				next new Error "MONGO"
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
