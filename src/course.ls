require! {
	"express"
	"async"
	"lodash":"_"
	"mongoose"
	"winston"
	"./app"
}
ObjectId = mongoose.Types.ObjectId
User = mongoose.models.User
Semester = mongoose.models.Semester
Course = mongoose.models.Course
router = express.Router!
router
	..use /^\/(.{24})(.*?)?$/i (req, res, next)->
		res.locals.needs = 1
		app.locals.authorize req, res, next
	..use /^\/(.{24})(.*?)?$/i (req, res, next)->
		err,result <- async.waterfall [
			(done)->
				req.params.course = req.params.0
				# res.locals.course =
				done null, {
					"_id": req.params.course
					"school": app.locals.school
				}
			(course, done)->
				err, course, semester <- async.parallel [
					(para)->
						if res.locals.auth >= 3
							para null, course
						else
							para null
					(para)->
						if res.locals.auth is 2
							course.faculty = ObjectId res.locals.uid
							para null, course
						else
							para null
					(para)->
						if res.locals.auth is 1
							err, semester <- Semester.find {
								"open":{
									"$lt": new Date Date.now!
								}
								"close":{
									"$gt": new Date Date.now!
								}
							}
							.lean!
							.exec
							course.students = ObjectId res.locals.uid
							course.semester = {
								"$in": _.pluck semester, "_id"
							}
							para err, course
						else
							para null
					(para)->
						/* istanbul ignore if */
						if !res.locals.auth? or res.locals.auth <= 0
							para "UNAUTHORIZED"
						else
							para null
				]
				course = _(course)
				.without undefined
				.flatten true
				.value!
				/* istanbul ignore else */
				if course.length <= 1
					done err, course.0
				else
					done "TOO MANY", req.session
			(course, done)->
				err, result <- Course.findOne course
				.populate "semester"
				.populate {
					path: "students"
					sort: { "lastName": 1 }
				}
				.populate {
					path: "faculty"
					sort: { "lastName": 1 }
				}
				.exec
				res.locals.course? = result
				done err, result
		]
		/* istanbul ignore if */
		if err?
			switch err
			| "LOGOUT"
				err <- req.session.destroy
				winston.error "course.ls: session.destroy", err if err?
				res.redirect "/login"
			| "MONGO"
				winston.error "course.ls: Course.findOne", err
				next new Error "MONGO"
			| _
				winston.error "course.ls: async.waterfall", err
				next new Error err
		else
			if result?
				next "route"
			else
				next new Error "NOT FOUND"
	..use "/:course/assignments", require("./course/assignments")
	..use "/:course/assignment", require("./course/assignment")
	..use "/:course/attempt", require("./course/attempt")
	..use "/:course/blog", require("./course/blog")
	..use "/:course/conference", require("./course/conference")
	..use "/:course/thread", require("./course/thread")
	..use "/:course/post", require("./course/post")
	..use "/:course/grades", require("./course/grades")
	..use "/:course/roster", require("./course/roster")
	..use "/:course/settings", require("./course/settings")
	..use "/:course", require("./course/index")

module.exports = router
