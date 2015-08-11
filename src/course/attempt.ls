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
		err <- async.waterfall [
			(done)->
				# find attempt
				res.locals.attempt = {
					course: ObjectId res.locals.course._id
					_id: ObjectId req.params.attempt
				}
				done null
			(done)->
				if res.locals.auth is 1
					res.locals.attempt.author = ObjectId res.locals.uid
				done null
			(done)->
				err, result <- Attempt.findOne res.locals.attempt
				.populate "assignment"
				.populate "author"
				.exec
				done err,result
			(result,done)->
				if result?
					res.locals.attempt = result
				done null, result
			(result,done)->
				if result.assignment?
					res.locals.assignment = result.assignment
				done null
		]
		if err
			switch err
			| "fin"
				break
			| _
				winston.error "attempt.ls: attempt.findOne", err
				next new Error "MONGO"
		else
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
			if req.body.points?
				req.body.points = parseInt req.body.points, 10
			if !req.body.points? or not (req.body.points >= 0) # double check require field exists & is valid
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
