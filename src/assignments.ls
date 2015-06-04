module.exports = (app)->
	require! {
		"async"
		"lodash"
		"moment"
		"mongoose"
		"util"
		"winston"
	}
	ObjectId = mongoose.Types.ObjectId
	_ = lodash
	User = mongoose.models.User
	Course = mongoose.models.Course
	Assignment = mongoose.models.Assignment
	Attempt = mongoose.models.Attempt
	app
		..route "/:route(c|C|course)?/:course/assignments/:assign?/:attempt?" # query :: action(new|edit|delete|grade)
		.all (req, res, next)->
			# to be in course auth needs to be min = 1
			res.locals.needs = 1
			app.locals.authorize req, res, next
		.all (req, res, next)->
			# assign & attempt have to be mongo id"s
			if req.params.assign? and req.params.assign.length isnt 24
				winston.info "Bad Assignment"
				next new Error "Bad Assignment"
			else if req.params.attempt? and req.params.attempt.length isnt 24
				winston.info "Bad Attempt"
				next new Error "Bad Attempt"
			else
				res.locals.course = {
					"id": req.params.course
					"school": app.locals.school
				}
				/* istanbul ignore else there should be no way to hit that. */
				if res.locals.auth >= 3
					next!
				else if res.locals.auth is 2
					res.locals.course.faculty = ObjectId res.locals.uid
					next!
				else if res.locals.auth is 1
					res.locals.course.students = ObjectId res.locals.uid
					next!
				else
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
			# get assign_id
			<- async.parallel [
				(done)->
					# default view
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
						.exec
						/* istanbul ignore if should only really occur if db crashes */
						if err
							winston.error "assign findOne conf", err
							next new Error "INTERNAL"
						else
							res.locals.assignments = if result.length isnt 0 then _.sortBy result, "timestamp" .reverse! else []
							done!
					else
						done!
				(done)->
					# assignment view
					if req.params.assign? && !req.params.attempt?
						# grab the assignment
						err, result <- Assignment.findOne {
							course: ObjectId res.locals.course._id
							_id: ObjectId req.params.assign
						}
						.populate "author"
						.exec
						/* istanbul ignore if should only really occur if db crashes */
						if err
							winston.error "assign findOne conf", err
							next new Error "INTERNAL"
						else
							if result?
								res.locals.assignment = result.toObject!
							else
								res.locals.error = "NOT FOUND"
							done!
					else
						done!
				(done)->
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
						/* istanbul ignore if should only really occur if db crashes */
						if err
							winston.error "assign findOne conf", err
							next new Error "INTERNAL"
						else
							if result?
								res.locals.attempts = result
								done!
							else
								next new Error "NOT FOUND"
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
						.sort!
						.exec
						/* istanbul ignore if should only really occur if db crashes */
						if err
							winston.error "assign findOne conf", err
							next new Error "INTERNAL"
						else
							if result?
								res.locals.attempts = if result.length isnt 0 then _.sortBy result, "timestamp" .reverse! else []
								done!
							else
								next new Error "NOT FOUND"
					else
						done!
			]
			if res.locals.error?
				next new Error res.locals.error
			else
				next!
		.get (req, res, next)->
			async.parallel [
				(done)->
					if !req.query.action? && !req.params.assign?
						# show list of assignments by title
						res.render "assignments/default"
				(done)->
					if !req.query.action? && req.params.assign?
						if req.params.attempt?
							# show attempt
							res.render "assignments/attempt"
						else
							# show assignment details & attempt field
							res.render "assignments/view"
				(done)->
					if req.query.action?
						next! # don't assume action, continue trying
			]
		.post (req, res, next)->
			# handle new attempt
			switch req.query.action
			| "attempt"
				if !req.body.aid? or !req.body.text?
					res.status 400 .render "assignments/view" { body: req.body, success:"error", error:"Attempt Text Can <b>not</b> be blank." }
				else
					<- async.parallel [
						(done)->
							err, result <- Attempt.find {
								course: ObjectId res.locals.course._id
								author: ObjectId res.locals.uid
								assignment: ObjectId req.body.aid
							}
							.count!
							.exec
							/* istanbul ignore if should only really occur if db crashes */
							if err
								winston.error "attempt find conf",err
								next new Error "INTERNAL"
							else
								res.locals.tries = result
								done err
						(done)->
							err, result <- Assignment.findOne {
								"course": ObjectId res.locals.course._id
								"_id": ObjectId req.body.aid
							}
							.populate "author"
							.exec
							/* istanbul ignore if should only really occur if db crashes */
							if err
								winston.error "assign find conf",err
								next new Error "INTERNAL"
							else
								res.locals.assignment = result
								done err
					]
					err <- async.waterfall [
						(cont)->
							# date now gt start
							if (new Date Date.now!) > res.locals.assignment.start
								cont null
							else
								cont "Allowed assignment submission window has not opened."
						(cont)->
							# no end OR date now < end OR allowLate is true
							if !res.locals.assignment.end? or ((new Date Date.now!) < Date.parse(res.locals.assignment.end)) or (res.locals.assignment.allowLate is true)
								cont null
							else
								cont "Allowed assignment submission window has closed."
						(cont)->
							# only if my attempts are less than assignment tries create the new attempt
							if !res.locals.assignment.tries? or res.locals.assignment.tries > res.locals.tries
								cont null
							else
								cont "You have no more attempts."
						(cont)->
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
							/* istanbul ignore if should only really occur if db crashes */
							if err?
								winston.error err
								cont "Mongo Error"
							else
								res.redirect "/#{req.params.course}/assignments/#{req.params.assign}/#{attempt._id.toString!}"
								cont null
					]
					if err and err isnt "redirect" and err isnt "Mongo Error"
						res.status 400
						res.render "assignments/view" { body:req.body, success:"error", error:err }
					else if err is "Mongo Error"
						next new Error "Mongo Error"
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
				res.render "assignments/create"
			| "edit"
				res.render "assignments/edit"
			| "delete"
				res.render "assignments/del"
			| _
				next! # don't assume action
		.put (req, res, next)->
			# handle edit assignment
			switch req.query.action
			| "edit"
				if !req.body.aid? || !req.body.title? || !req.body.text? || !req.body.tries? # double check require fields exist
					res.status 400 .render "assignments/edit" { body: req.body, success:"no", action:"edit" }
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
					if !req.body.total?
						delete assign.totalPoints
					if !moment(res.locals.start).isValid!
						delete assign.start
					if res.locals.assignment.end? and ( !req.body.closedate? or req.body.closedate is "" )
						assign.end = ""
					else if !moment(res.locals.end).isValid!
						delete assign.end
					err, assign <- Assignment.findOneAndUpdate {
						"_id": ObjectId req.body.aid
						"course": ObjectId res.locals.course._id
						# don't check for author as me might not be...
					}, assign
					/* istanbul ignore if should only really occur if db crashes */
					if err?
						winston.error err
						next new Error "Mongo Error"
					else
						res.redirect "/#{req.params.course}/assignments/#{assign._id.toString!}"
			| _
				next! # don't assume action
		.post (req, res, next)->
			# handle new assignment
			switch req.query.action
			| "new"
				if !req.body.title? || !req.body.text? || !req.body.tries? # double check require fields exist
					res.status 400 .render "assignments/create" { body: req.body, success:"no", action:"edit"}
				else
					res.locals.start = new Date req.body.opendate+" "+req.body.opentime
					res.locals.end = new Date req.body.closedate+" "+req.body.closetime
					assign = {
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
					if !moment(res.locals.start).isValid!
						delete assign.start
					if !moment(res.locals.end).isValid!
						delete assign.end
					assignment = new Assignment assign
					err, assignment <- assignment.save
					/* istanbul ignore if should only really occur if db crashes */
					if err?
						winston.error err
						next new Error "INTERNAL"
					else
						res.status 302 .redirect "/#{req.params.course}/assignments/" + assignment._id
			| "grade"
				if !req.body.points? || !req.body.aid? # double check require fields exist
					res.status 400 .render "assignments/create" { assignments: [req.body], -success, action:"edit" }
				else
					err, attempt <- Attempt.findOneAndUpdate {
						"course": ObjectId res.locals.course._id
						"_id": ObjectId req.body.aid
					}, {
						"points": req.body.points
					}
					/* istanbul ignore if should only really occur if db crashes */
					if err?
						winston.error err
						next new Error "INTERNAL"
					else
						res.status 302 .redirect "/#{req.params.course}/assignments/#{req.params.assign}/#{attempt._id.toString!}"
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
				/* istanbul ignore if should only really occur if db crashes */
				if err?
					winston.error err
					next new Error "INTERNAL"
				else
					err, assignments <- Assignment.remove {
						"_id": ObjectId req.body.aid
						"course": ObjectId res.locals.course._id
					}
					/* istanbul ignore if should only really occur if db crashes */
					if err?
						winston.error err
						next new Error "INTERNAL"
					else
						res.status 302 .redirect "/#{req.params.course}/assignments"
			| _
				next! # don't assume action
