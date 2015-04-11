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
	..use (req, res, next)->
		console.log 'course.ls req.params',req.params
		res.locals.needs = 1
		if res.locals.auth? and res.locals.needs? and res.locals.needs <= res.locals.auth
			next!
		else
			next new Error "UNAUTHORIZED"
	..use (req, res, next)->
		res.locals.course = {
			"id": req.params.course
			"school": req.app.locals.school
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
	..use (req, res, next)->
		err, result <- Course.findOne res.locals.course
		/* istanbul ignore if should only really occur if db crashes */
		if err
			winston.error "course findOne conf", err
			next new Error "INTERNAL"
		else
			if !result? or result.length is 0
				next new Error "NOT FOUND"
			else
				res.locals.course = result
				next!
# sub routes
app
	..use '/:course/dash', require('./courseDash')
	..use '/:course/assignments', require('./assignments')
	..use '/:course/blog', require('./blog')
	..use '/:course/conference', require('./conference')
	..use '/:course/grades', require('./grades')

module.exports = app
