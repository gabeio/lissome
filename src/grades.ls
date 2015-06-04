module.exports = (app)->
	require! {
		"async"
		"mongoose"
		"winston"
	}
	ObjectId = mongoose.Types.ObjectId
	Course = mongoose.models.Course
	Assignment = mongoose.models.Assignment
	Attempt = mongoose.models.Attempt
	app
		..route "/:route(c|C|course)?/:course/grades"
		.all (req, res, next)->
			res.locals.needs = 1
			app.locals.authorize req, res, next
		.all (req,res,next)->
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
		.all (req, res, next)->
			err, result <- Attempt.find {
				course: ObjectId res.locals.course._id
				author: ObjectId res.locals.uid
			}
			.populate "assignment"
			.populate "author"
			.sort!
			.exec
			if err?
				winston.error "assign findOne conf", err
				next new Error "INTERNAL"
			else
				res.locals.attempts = result
				next!
		.get (req, res, next)->
			res.render "grades"
