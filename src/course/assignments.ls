require! {
	"express"
	"async"
	"lodash"
	"moment"
	"mongoose"
	"util"
	"winston"
	"../app"
}
ObjectId = mongoose.Types.ObjectId
_ = lodash
Assignment = mongoose.models.Assignment
Attempt = mongoose.models.Attempt
router = express.Router!
router
	..route "/:assign?/:attempt?" # query :: action(new|edit|delete|grade)
	.all (req, res, next)->
		# get assign_id
		err <- async.parallel [
			(para)->
				# (default view)
				# no assignment given
				# no attempt given
				if !req.params.assign? && !req.params.attempt?
					# find all assignments
					res.locals.assignments = {
						course: ObjectId res.locals.course._id
					}
					if res.locals.auth is 1
						res.locals.assignments.start = {
							"$lt": new Date Date.now!
						}
					err, result <- Assignment.find res.locals.assignments
					.populate "author"
					.sort { timestamp: -1 }
					.exec
					/* istanbul ignore if should only occur if db crashes */
					if err
						winston.error "assign findOne conf", err
						para "INTERNAL"
					else
						res.locals.assignments = if result.length isnt 0 then result else []
						para!
				else
					para!
			(para)->
				# (assignment view)
				# assignment given
				# no attempt given
				if req.params.assign? && !req.params.attempt?
					# grab the assignment
					err, result <- Assignment.findOne {
						course: ObjectId res.locals.course._id
						_id: ObjectId req.params.assign
					}
					.populate "author"
					.exec
					/* istanbul ignore if should only occur if db crashes */
					if err
						winston.error "assign findOne conf", err
						para "INTERNAL"
					else
						if result?
							res.locals.assignment = result.toObject!
							para!
						else
							para "NOT FOUND"
				else
					para!
			(para)->
				# attempt given
				if req.params.attempt?
					# findOne attempt
					res.locals.attempts = {
						course: ObjectId res.locals.course._id
						assignment: ObjectId req.params.assign
						_id: ObjectId req.params.attempt
					}
					if res.locals.auth is 1
						res.locals.attempts.author = ObjectId res.locals.uid
					err, result <- Attempt.findOne res.locals.attempts
					.populate "assignment"
					.populate "author"
					.exec
					/* istanbul ignore if should only occur if db crashes */
					if err
						winston.error "assign findOne conf", err
						para "INTERNAL"
					else
						if result?
							res.locals.attempts = result
							para!
						else
							para "NOT FOUND"
				else if req.params.assign?
					# find attempts
					res.locals.attempts = {
						course: ObjectId res.locals.course._id
						assignment: ObjectId req.params.assign
					}
					if res.locals.auth is 1
						res.locals.attempts.author = ObjectId res.locals.uid
					err, result <- Attempt.find res.locals.attempts
					.populate "assignment"
					.populate "author"
					.sort { timestamp: -1 }
					.exec
					/* istanbul ignore if should only occur if db crashes */
					if err
						winston.error "(conference) (params:assign) findOne", err
						para "INTERNAL"
					else
						/* istanbul ignore else should never occur */
						if result?
							res.locals.attempts = result
							# res.locals.attempts = if result.length isnt 0 then _.sortBy result, "timestamp" .reverse! else []
							para!
						else
							para "NOT FOUND"
				else
					para!
		]
		if err
			next new Error err
		else
			next!
	.get (req, res, next)->
		async.parallel [
			(done)->
				if !req.query.action? && !req.params.assign?
					# show list of assignments by title
					res.render "course/assignments/default", { success: req.query.success, action: req.query.verb, csrf: req.csrfToken! }
			(done)->
				if !req.query.action? && req.params.assign?
					if req.params.attempt?
						# show attempt
						res.render "course/assignments/attempt", { success: req.query.success, action: req.query.verb, csrf: req.csrfToken! }
					else
						# show assignment details & attempt field
						res.render "course/assignments/view", { success: req.query.success, action: req.query.verb, csrf: req.csrfToken! }
			(done)->
				if req.query.action?
					next! # don't assume action, continue trying
		]
	.post (req, res, next)->
		# handle new attempt
		switch req.query.action
		| "attempt"
			if !req.body.aid? or !req.body.text?
				res.status 400 .render "course/assignments/view" { body: req.body, success:"error", error:"Attempt Text Can <b>not</b> be blank.", csrf: req.csrfToken! }
			else
				# find all tries related to user & assignment
				err, result <- Attempt.find {
					course: ObjectId res.locals.course._id
					author: ObjectId res.locals.uid
					assignment: ObjectId req.body.aid
				}
				.count!
				.exec
				res.locals.tries = result
				err <- async.parallel [
					(cont)->
						# date now gt start
						if (new Date Date.now!) > res.locals.assignment.start
							cont null
						else
							cont "Allowed assignment submission window has not opened."
					(cont)->
						# no end OR date now < end OR allowLate is true
						if !res.locals.assignment.end? or res.locals.assignment.end is "" or ((new Date Date.now!) < Date.parse(res.locals.assignment.end)) or (res.locals.assignment.allowLate is true)
							cont null
						else
							cont "Allowed assignment submission window has closed."
					(cont)->
						# only if my attempts are less than assignment tries create the new attempt
						if !res.locals.assignment.tries? or res.locals.assignment.tries > res.locals.tries
							cont null
						else
							cont "You have no more attempts."
				]
				if err
					res.status 400 .render "course/assignments/view" { body:req.body, success:"error", error:err, csrf: req.csrfToken! }
				else
					res.locals.body = {
						assignment: ObjectId req.body.aid
						course: ObjectId res.locals.course._id
						text: req.body.text
						author: ObjectId res.locals.uid
					}
					if res.locals.assignment.end? and (new Date Date.now!) > Date.parse(res.locals.assignment.end)
						res.locals.body.late = true
					res.locals.attempt = new Attempt res.locals.body
					err, attempt <- res.locals.attempt.save
					/* istanbul ignore if should only occur if db crashes */
					if err
						winston.error err
						next new Error "Mongo Error"
					else
						res.redirect "/c/#{res.locals.course._id}/assignments/#{req.params.assign}/#{attempt._id.toString!}"
		| _
			next! # not an attempt
	.all (req, res, next)->
		# to modify assignments you need to be faculty+
		res.locals.needs = 2
		app.locals.authorize req, res, next
	### EVERYTHING AFTER HERE IS FACULTY+ ###
	.get (req, res, next)->
		switch req.query.action
		| "new"
			res.render "course/assignments/create", { csrf: req.csrfToken! }
		| "edit"
			res.render "course/assignments/edit", { csrf: req.csrfToken! }
		| "delete"
			res.render "course/assignments/del", { csrf: req.csrfToken! }
		| _
			next! # don't assume action
	.put (req, res, next)->
		# handle edit assignment
		switch req.query.action
		| "edit"
			if !req.body.aid? || !req.body.title? || !req.body.text? || !req.body.tries? || req.body.title is "" || req.body.text is "" # double check require fields exist
				res.status 400 .render "course/assignments/edit" { body: req.body, success:"no", action:"edit", csrf: req.csrfToken! }
			else
				res.locals.start = new Date(req.body.opendate+" "+req.body.opentime)
				res.locals.end = new Date(req.body.closedate+" "+req.body.closetime)
				assign = {
					title: req.body.title
					text: req.body.text
					start: res.locals.start
					end: res.locals.end
					tries: req.body.tries
					allowLate: if req.body.late is "yes" then true else false
					totalPoints: req.body.total
				}
				if !req.body.total? or req.body.total is ""
					delete assign.totalPoints
				if !moment(res.locals.start).isValid!
					delete assign.start
				if res.locals.assignment.end? and ( !req.body.closedate? or req.body.closedate is "" )
					assign.end = "" # delete it if it already exists
				else if !moment(res.locals.end).isValid!
					delete assign.end
				err, assign <- Assignment.findOneAndUpdate {
					"_id": ObjectId req.body.aid
					"course": ObjectId res.locals.course._id
					# don't check for author as me might not be...
				}, assign
				/* istanbul ignore if should only occur if db crashes */
				if err?
					winston.error err
					next new Error "Mongo Error"
				else
					res.redirect "/c/#{res.locals.course._id}/assignments/#{assign._id.toString!}"
		| _
			next! # don't assume action
	.post (req, res, next)->
		switch req.query.action
		| "new" # handle new assignment
			async.parallel [
				(para)->
					if !req.body.title? or !req.body.text? or !req.body.tries? or req.body.title is "" or req.body.text is "" # double check require fields exists
						res.status 400 .render "course/assignments/create" { body: req.body, success:"no", action:"edit", csrf: req.csrfToken! }
				(para)->
					if req.body.title? and req.body.text? and req.body.tries? and req.body.title isnt "" and req.body.text isnt ""
						res.locals.start = new Date req.body.opendate+" "+req.body.opentime
						res.locals.end = new Date req.body.closedate+" "+req.body.closetime
						res.locals.assign = {
							title: req.body.title
							text: req.body.text
							start: res.locals.start
							end: res.locals.end
							tries: req.body.tries
							allowLate: if req.body.late is "yes" then true else false
							totalPoints: req.body.total
							# unchangeable
							author: ObjectId res.locals.uid
							course: res.locals.course._id
						}
						<- async.parallel [
							(para)->
								if !moment(res.locals.start).isValid!
									delete res.locals.assign.start
									para!
								else
									para!
							(para)->
								if !moment(res.locals.end).isValid!
									delete res.locals.assign.end
									para!
								else
									para!
						]
						assignment = new Assignment res.locals.assign
						err, assignment <- assignment.save
						/* istanbul ignore if should only occur if db crashes */
						if err?
							winston.error err
							next new Error "INTERNAL"
						else
							res.status 302 .redirect "/c/#{res.locals.course._id}/assignments/" + assignment._id
			]
		| "grade" # handle assignment grading
			req.body.points? = parseInt req.body.points
			if req.body.points === NaN or !req.body.aid? # double check require fields exist
				res.status 400 .render "course/assignments/attempt", { success:"no", action:"graded", csrf: req.csrfToken! }
				# res.status 400 .render "course/assignments/create" { assignments: [req.body], -success, action:"edit", csrf: req.csrfToken! }
			else
				err, attempt <- Attempt.findOneAndUpdate {
					"course": ObjectId res.locals.course._id
					"_id": ObjectId req.params.attempt
					# "_id": ObjectId req.body.aid
				}, {
					"points": req.body.points
				}
				/* istanbul ignore if should only occur if db crashes */
				if err?
					winston.error err
					next new Error "INTERNAL"
				else
					res.status 302 .redirect "/c/#{res.locals.course._id}/assignments/#{req.params.assign}/#{req.params.attempt}?success=yes&verb=graded"
					# res.render "course/assignments/attempt", { success:"yes", action:"graded", csrf: req.csrfToken! }
		| _
			next! # don't assume action
	.delete (req, res, next)->
		# handle delete assignment (faculty+)
		switch req.query.action
		| "delete"
			err, attempts <- Attempt.remove {
				"assignment": ObjectId req.body.aid
				"course": ObjectId res.locals.course._id
			}
			/* istanbul ignore if should only occur if db crashes */
			if err?
				winston.error err
				next new Error "INTERNAL"
			else
				err, assignments <- Assignment.remove {
					"_id": ObjectId req.body.aid
					"course": ObjectId res.locals.course._id
				}
				/* istanbul ignore if should only occur if db crashes */
				if err?
					winston.error err
					next new Error "INTERNAL"
				else
					res.status 302
					res.redirect "/c/#{res.locals.course._id}/assignments?success=yes&verb=deleted"
		| _
			next! # don't assume action

module.exports = router
