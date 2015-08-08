require! {
	"express"
	"async"
	"lodash":"_"
	"moment"
	"mongoose"
	"winston"
	"../app"
}
parser = app.locals.multer.fields []
ObjectId = mongoose.Types.ObjectId
Assignment = mongoose.models.Assignment
Attempt = mongoose.models.Attempt
router = express.Router!
router
	..route "/:attempt/:action?" # query :: action(new|edit|delete|grade)
	.all (req, res, next)->
		# find attempt
		res.locals.attempt = {
			course: ObjectId res.locals.course._id
			# assignment: ObjectId req.params.assign
			_id: ObjectId req.params.attempt
		}
		if res.locals.auth is 1
			res.locals.attempt.author = ObjectId res.locals.uid
		err, result <- Attempt.findOne res.locals.attempt
		.populate "assignment"
		.populate "author"
		.exec
		/* istanbul ignore if should only occur if db crashes */
		if err
			winston.error "attempt.ls: attempt.findOne", err
			next new Error "MONGO"
		else
			res.locals.attempt? = result
			res.locals.assignment? = result.assignment
			next!
	.get (req, res, next)->
		async.parallel [
			(done)->
				if !req.params.action? && req.params.attempt?
					# show attempt
					res.render "course/assignments/attempt", { success: req.query.success, action: req.query.verb, csrf: req.csrfToken! }
			(done)->
				if req.params.action?
					next! # don't assume action, continue trying
		]
	.all (req, res, next)->
		# to modify assignments you need to be faculty+
		res.locals.needs = 2
		app.locals.authorize req, res, next
	### EVERYTHING AFTER HERE IS FACULTY+ ###
	.post parser, (req, res, next)->
		switch req.params.action
		| "grade" # handle assignment grading
			req.body.points? = parseInt req.body.points
			if req.body.points === NaN # double check require fields exist
				res.status 400 .render "course/assignments/attempt", { success: "no", action: "graded", csrf: req.csrfToken! }
			else
				err, attempt <- Attempt.findOneAndUpdate {
					"course": ObjectId res.locals.course._id
					"_id": ObjectId req.params.attempt
				}, {
					"points": req.body.points
				}
				/* istanbul ignore if should only occur if db crashes */
				if err?
					winston.error err
					next new Error "INTERNAL"
				else
					res.status 302 .redirect "/c/#{res.locals.course._id}/attempt/#{req.params.attempt}?success=yes&verb=graded"
		| _
			next! # don't assume action

module.exports = router
