require! {
	"express"
}
app = express.Router()
require! {
	"mongoose"
	"winston"
}
ObjectId = mongoose.Types.ObjectId
Course = mongoose.models.Course
Post = mongoose.models.Post
# middleish ware
app
	..route "/:course"
	.all (req, res, next)->
		res.locals.needs = 1
		next!
	.all (req, res, next)->
		if res.locals.auth? and res.locals.needs? and res.locals.needs <= res.locals.auth
			next!
		else
			next new Error "UNAUTHORIZED"
	.all (req, res, next)->
		res.locals.course = {
			"id": req.params.course
			"school": app.locals.school
		}
		/* istanbul ignore default there should be no way to hit that. */
		switch res.locals.auth
		| 3
			next!
		| 2
			res.locals.course.faculty = ObjectId res.locals.uid
			next!
		| 1
			res.locals.course.students = ObjectId res.locals.uid
			next!
		| _
			next new Error "UNAUTHORIZED"
# sub routes
app
	..use '/:course',require('./courseDash')
	..use '/:course/assignments',require('./assignments')
	..use '/:course/blog',require('./blog')
	..use '/:course/conference',require('./conference')
	..use '/:course/grades',require('./grades')

module.exports = app
