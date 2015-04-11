require! {
	"express"
}
app = express.Router()
require! {
	"async"
	"lodash"
	"mongoose"
	"winston"
}
ObjectId = mongoose.Types.ObjectId
_ = lodash
Course = mongoose.models.Course
app
	..route "/"
	.all (req, res, next)->
		console.log 'dashboard.ls req.params', req.params
	.all (req, res, next)->
		res.locals.needs = 1
		next!
	.all (req, res, next)->
		if res.locals.auth? and res.locals.needs? and res.locals.needs <= res.locals.auth
			next!
		else
			next new Error "UNAUTHORIZED"
	.all (req, res, next)->
		res.locals.courses = {
			"school": req.app.locals.school
		}
		/* istanbul ignore default there should be no way to hit that. */
		switch res.locals.auth
		| 3
			next!
		| 2
			res.locals.courses.faculty = ObjectId res.locals.uid
			next!
		| 1
			res.locals.courses.students = ObjectId res.locals.uid
			next!
		| _
			next new Error "UNAUTHORIZED"
	.all (req, res, next)->
		console.log res.locals.courses
		err, result <- Course.find res.locals.courses
		/* istanbul ignore if should only really occur if db crashes */
		if err?
			winston.error "course findOne conf", err
			next new Error "INTERNAL"
		else
			console.log result
			if !result? or result.length is 0
				next new Error "NOT FOUND"
			else
				res.locals.courses = result
				next!
	.get (req, res, next)->
		res.render "dashboard"

module.exports = app
