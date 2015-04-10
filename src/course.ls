require! {
	"express"
}
app = express.Router()
require! {
	"mongoose"
	"winston"
}
ObjectId = mongoose.Types.ObjectId
Course = app.locals.models.Course
Post = app.locals.models.Post
app
	..route "/:course/settings"
	.all (req, res, next)->
		res.locals.needs = 2 # maybe 3
		app.locals.authorize req, res, next
	.all (req, res, next)->
		res.locals.on = "course"
		...
	.get (req, res, next)->
		res.send "this will allow showing of course settings"
		/*
		err,result <- Course.find { "id":req.params.course, "school":app.locals.school }
		if err?
			winston.error err
		if !result[0]?
			next new Error "NOT FOUND"
		else
			res.send result
		*/
	.post (req, res, next)->
		next new Error "NOT IMPL"
		/*
		err,result <- Course.update { "id":req.params.course, "school":app.locals.school }, {}
		if err?
			winston.error err
		if !result[0]?
			next new Error "NOT FOUND"
		else
			res.send result
		*/

	..route "/:course/:index(index|dash|dashboard)?"
	.all (req, res, next)->
		res.locals.needs = 1
		app.locals.authorize req, res, next
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
	.all (req, res, next)->
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
	.get (req, res, next)->
		res.render "course"

module.exports = app
