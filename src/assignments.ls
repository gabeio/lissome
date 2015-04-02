module.exports = (app)->
	require! {
		'async'
		'lodash'
		'moment'
		'mongoose'
		'util'
		'winston'
	}
	ObjectId = mongoose.Types.ObjectId
	_ = lodash
	User = app.locals.models.User
	Course = app.locals.models.Course
	Assignment = app.locals.models.Assignment
	Attempt = app.locals.models.Attempt
	app
		..route '/:course/assignments/:assign?/:attempt?' # query :: action(new|edit|delete|grade)
		.all (req, res, next)->
			# to be in course auth needs to be min = 1
			res.locals.needs = 1
			app.locals.authorize req, res, next
		.all (req, res, next)->
			# assign & attempt have to be mongo id's
			if req.params.assign? and req.params.assign.length isnt 24
				next new Error 'Bad Assignment'
			else if req.params.attempt? and req.params.assign.length isnt 24
				next new Error 'Bad Attempt'
			else
				next!
		.all (req, res, next)->
			# get course_id
			<- async.parallel [
				(done)->
					if res.locals.auth is 3
						err, result <- Course.findOne {
							'id': req.params.course
							'school': app.locals.school
						}
						res.locals.course = result
						done!
					else
						done!
				(done)->
					if res.locals.auth is 2
						err, result <- Course.findOne {
							'id': req.params.course
							'school': app.locals.school
							'faculty': ObjectId res.locals.uid
						}
						res.locals.course = result
						done!
					else
						done!
				(done)->
					if res.locals.auth is 1
						err, result <- Course.findOne {
							'id': req.params.course
							'school': app.locals.school
							'students': ObjectId res.locals.uid
						}
						res.locals.course = result
						done!
					else
						done!
			]
			if res.locals.course?
				next!
			else
				next new Error 'UNAUTHORIZED'
		.all (req, res, next)->
			# get assign_id
			<- async.parallel [
				(done)->
					# default view
					if !req.params.assign? && !req.params.attempt?
						# find all assignments
						err, result <- Assignment.find {
							course: ObjectId res.locals.course._id
						}
						.populate 'author'
						.exec
						res.locals.assignments = if result.length isnt 0 then _.sortBy result, 'timestamp' .reverse! else []
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
						.populate 'author'
						.exec
						res.locals.assignment = result.toObject!
						done!
					else
						done!
				(done)->
					# faculty+
					if res.locals.auth >= 2
						if req.params.attempt?
							# findOne attempt
							err, result <- Attempt.findOne {
								course: ObjectId res.locals.course._id
								# assignment: ObjectId req.params.assign
								_id: ObjectId req.params.attempt
							}
							.populate 'assignment'
							.populate 'author'
							.exec
							res.locals.attempts = result
							done!
						else if req.params.assign?
							# find attempts
							err, result <- Attempt.find {
								course: ObjectId res.locals.course._id
								# assignment: ObjectId req.params.attempt
							}
							.populate 'assignment'
							.populate 'author'
							.exec
							res.locals.attempts = if result.length isnt 0 then _.sortBy result, 'timestamp' .reverse! else []
							done!
						else
							done!
					else
						done!
				(done)->
					# student
					if res.locals.auth is 1
						if req.params.attempt?
							# findOne attempt
							err, result <- Attempt.findOne {
								course: ObjectId res.locals.course._id
								author: ObjectId res.locals.uid
								_id: ObjectId req.params.attempt
							}
							.populate 'assignment'
							.populate 'author'
							.exec
							res.locals.attempts = result
							done!
						else if req.params.assign?
							# find attempts
							err, result <- Attempt.find {
								course: ObjectId res.locals.course._id
								author: ObjectId res.locals.uid
							}
							.populate 'assignment'
							.populate 'author'
							.exec
							res.locals.attempts = if result.length isnt 0 then _.sortBy result, 'timestamp' .reverse! else []
							done!
						else
							done!
					else
						done!
			]
			next!
		.get (req, res, next)->
			async.parallel [
				(done)->
					if !req.query.action? && !req.params.assign?
						# show list of assignments by title
						res.render 'assignments/default'
				(done)->
					if !req.query.action? && req.params.assign?
						if req.params.attempt?
							# show attempt
							res.render 'assignments/attempt'
						else
							# show assignment details & attempt field
							res.render 'assignments/view'
				(done)->
					if req.query.action?
						next! # don't assume action, continue trying
			]
		.post (req, res, next)->
			# handle new attempt
			switch req.query.action
			| 'attempt'
				if !req.body.aid? or !req.body.text?
					res.status 400 .render 'assignments/view' { body: req.body, success:'error', error:'Attempt Text Can <b>not</b> be blank.' }
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
							if err
								winston.error 'attempt:find',err
								next new Error 'Find Attempt'
							winston.info 'attempts',result
							res.locals.tries = result
							done err
						(done)->
							err, result <- Assignment.findOne {
								'course': ObjectId res.locals.course._id
								'_id': ObjectId req.body.aid
							}
							.populate 'author'
							.exec
							if err
								winston.error 'assign:find',err
								next new Error 'Find Assignment'
							winston.info 'assign',result.tries
							res.locals.assignment = result
							done err
					]
					# date now gt start
					if (new Date Date.now!) > res.locals.assignment.start
						# no end OR date now < end OR allowLate is true
						if !res.locals.assignment.end? or (new Date Date.now! < res.locals.assignment.end) or (res.locals.assignment.allowLate is true)
							# only if my attempts are less than assignment tries create the new attempt
							if !res.locals.assignment.tries? or res.locals.assignment.tries > res.locals.tries
								theAttempt = {
									assignment: ObjectId req.body.aid
									course: ObjectId res.locals.course._id
									text: req.body.text
									author: ObjectId res.locals.uid
								}
								if res.locals.assignment.end? and (new Date Date.now!) > res.locals.assignment.end
									theAttempt.late = true
								attempt = new Attempt theAttempt
								err, attempt <- attempt.save
								/* istanbul ignore if */
								if err?
									winston.error err
									next new Error 'Mongo Error'
								else
									res.redirect "/#{req.params.course}/assignments/#{req.params.assign}/#{attempt._id.toString!}"
							else
								res.status 400 .render 'assignments/view' { success:'error', error:'You have no more attempts.' }
						else
							res.status 400 .render 'assignments/view' { success:'error', error:'Allowed assignment submission time has closed.' }
					else
						res.status 400 .render 'assignments/view' { success:'error', error:'Allowed assignment submission time has not opened.' }
			| _
				next! # not an attempt
		.all (req, res, next)->
			# to modify assignments you need to be faculty+
			res.locals.needs = 2
			app.locals.authorize req, res, next
		### EVERYTHING AFTER HERE IS FACULTY+ ###
		.get (req, res, next)->
			# winston.info 'H'
			switch req.query.action
			| 'new'
				res.render 'assignments/create'
			| 'edit'
				res.render 'assignments/edit'
			| 'delete'
				res.render 'assignments/del'
			| _
				next! # don't assume action
		.put (req, res, next)->
			# winston.info 'I'
			# handle edit assignment
			switch req.query.action
			| 'edit'
				if !req.body.aid? || !req.body.title? || !req.body.text? || !req.body.tries? # double check require fields exist
					res.status 400 .render 'assignments/edit' { body: req.body, success:'no', action:'edit' }
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
						# winston.info 'I1'
						delete assign.totalPoints
					if !moment(res.locals.start).isValid!
						# winston.info 'I2'
						delete assign.start
					if !req.body.closedate?
						assign.end = ''
					else if !moment(res.locals.end).isValid!
						# winston.info 'I3'
						delete assign.end
					err, assign <- Assignment.findOneAndUpdate {
						'_id': ObjectId req.body.aid
						'course': ObjectId res.locals.course._id
						# don't check for author as me might not be...
					}, assign
					if err?
						# winston.info 'I4'
						winston.error err
						next new Error 'Mongo Error'
					else
						# winston.info 'I5'
						res.redirect "/#{req.params.course}/assignments/#{assign._id.toString!}"
			| _
				next! # don't assume action
		.post (req, res, next)->
			# winston.info 'J'
			# handle new assignment
			switch req.query.action
			| 'new'
				if !req.body.title? || !req.body.text? || !req.body.tries? # double check require fields exist
					res.status 400 .render 'assignments/create' { body: req.body, success:'no', action:'edit'}
				else
					# winston.info 'J1'
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
					/* istanbul ignore if */
					if err?
						winston.error err
						next new Error 'Mongo Error'
					else
						res.status 302 .redirect "/#{req.params.course}/assignments/" + assignment._id
			| 'grade'
				# winston.info 'J2'
				if !req.body.points? || !req.body.aid? # double check require fields exist
					res.status 400 .render 'assignments/create' { assignments: [req.body], -success, action:'edit' }
				else
					err, attempt <- Attempt.findOneAndUpdate {
						'course': ObjectId res.locals.course._id
						'_id': ObjectId req.body.aid
					}, {
						'points': req.body.points
					}
					# winston.info attempt
					if err?
						winston.error err
						next new Error 'Mongo Error'
					else
						res.status 302 .redirect "/#{req.params.course}/assignments/#{req.params.assign}/#{attempt._id.toString!}"
			| _
				next! # don't assume action
		.delete (req, res, next)->
			# winston.info 'K'
			# handle delete assignment (faculty+)
			switch req.query.action
			| 'delete'
				err, attempts <- Attempt.remove {
					'assignment': ObjectId req.body.aid
					'course': ObjectId res.locals.course._id
				}
				# winston.info 'deleted:',attempts
				if err?
					winston.error err
					next new Error 'Mongo Error'
				else
					err, assignments <- Assignment.remove {
						'_id': ObjectId req.body.aid
						'course': ObjectId res.locals.course._id
					}
					# winston.info 'deleted:',assignments
					if err?
						winston.error err
						next new Error 'Mongo Error'
					else
						res.status 302 .redirect "/#{req.params.course}/assignments"
			# | 'deleteall'
			# 	# pluck only _id off of all assignments
			# 	plucked = _.pluck res.locals.assignments, '_id'
			# 	# winston.info 'pluck', plucked
			# 	# winston.info 'typeof plucked', typeof plucked.0
			# 	# convert all assignment._id's to ObjectIds
			# 	assignments = _.map plucked, ObjectId
			# 	# winston.info 'mapped', assignments
			# 	err, attempts <- Attempt.remove {
			# 		'assignment': {$in: assignments}
			# 		'course': ObjectId res.locals.course._id
			# 	}
			# 	# winston.info 'deleted:',attempts
			# 	if err?
			# 		winston.error err
			# 		next new Error 'Mongo Error'
			# 	else
			# 		err, assignments <- Assignment.remove {
			# 			'_id': {$in: assignments}
			# 			'course': ObjectId res.locals.course._id
			# 		}
			# 		# winston.info 'deleted:',assignments
			# 		if err?
			# 			winston.error err
			# 			next new Error 'Mongo Error'
			# 		else
			# 			res.status 302 .redirect "/#{req.params.course}/assignments"
			| _
				next! # don't assume action
