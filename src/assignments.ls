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
	Post = app.locals.models.Post
	Assignment = app.locals.models.Assignment
	Attempt = app.locals.models.Attempt
	app
		..route '/:course/:application(a|assign|assignment|assignments)/:assign?/:attempt?' # query :: action(new|edit|delete|grade)
		.all (req, res, next)->
			# winston.info req.originalUrl
			# winston.info 'params',req.params
			# winston.info 'query',req.query
			# winston.info 'body',req.body
			# winston.info 'A'
			# to be in course auth needs to be min = 1
			res.locals.needs = 1
			app.locals.authorize req, res, next
		.all (req, res, next)->
			# winston.info 'B'
			# do for every request
			# get course_id
			res.locals.on = 'assignments'
			<- async.parallel [
				(done)->
					if req.session.auth is 3
						# winston.info 'B1'
						err, result <- Course.findOne {
							'id': req.params.course
							'school': app.locals.school
						}
						res.locals.course = result
						done!
					else
						# winston.info 'B2'
						done!
				(done)->
					if req.session.auth is 2
						# winston.info 'B3'
						err, result <- Course.findOne {
							'id': req.params.course
							'school': app.locals.school
							'faculty': ObjectId req.session.uid
						}
						res.locals.course = result
						done!
					else
						# winston.info 'B4'
						done!
				(done)->
					if req.session.auth is 1
						# winston.info 'B5'
						err, result <- Course.findOne {
							'id': req.params.course
							'school': app.locals.school
							'students': ObjectId req.session.uid
						}
						res.locals.course = result
						done!
					else
						# winston.info 'B6'
						done!
			]
			if res.locals.course?
				# winston.info 'B7'
				next!
			else
				# winston.info 'B8'
				next new Error 'UNAUTHORIZED'
		.all (req, res, next)->
			# winston.info 'C'
			# do for every request
			# get assign_id
			<- async.parallel [
				(done)->
					if req.params.assign? && !req.params.attempt?
						# winston.info 'C1'
						# find assignment(s) w/ title
						err, result <- Assignment.find {
							school: app.locals.school
							course: ObjectId res.locals.course._id
							# optional stuff
							title: encodeURIComponent req.params.assign
						} .populate('author').exec
						res.locals.assignments = result
						done!
					else
						done!
				(done)->
					if !req.params.assign? && !req.params.attempt?
						# winston.info 'C2'
						# find all assignments
						err, result <- Assignment.find {
							school: app.locals.school
							course: ObjectId res.locals.course._id
						} .populate('author').exec
						res.locals.assignments = result
						done!
					else
						done!
			]
			# winston.info 'C3'
			next!
		.all (req, res, next)->
			# winston.info 'D'
			# split student|faculty
			# pluck only _id off of all assignments
			# plucked = _.pluck res.locals.assignments, '_id'
			# winston.info 'pluck', plucked
			# winston.info 'typeof plucked', typeof plucked.0
			# convert all assignment._id's to ObjectIds
			# assignments = _.map plucked, ObjectId
			# winston.info 'mapped', assignments
			# get attempt_id
			<- async.parallel [
				(done)->
					# faculty+
					if req.session.auth >= 2
						# winston.info 'D1'
						if req.params.attempt?
							# winston.info 'D11'
							# findOne attempt
							err, result <- Attempt.findOne {
								course: ObjectId res.locals.course._id
								# assignment: {$in: assignments}
								_id: ObjectId req.params.attempt
							} .populate('assignment').populate('author').exec
							res.locals.attempts = result
							done!
						else if req.params.assign?
							# winston.info 'D12'
							# find attempts
							err, result <- Attempt.find {
								course: ObjectId res.locals.course._id
								# assignment: {$in: assignments}
							} .populate('assignment').populate('author').exec
							res.locals.attempts = result
							done!
						else
							done!
					else
						done!
				(done)->
					# student
					if req.session.auth is 1
						# winston.info 'D2'
						if req.params.attempt?
							# winston.info 'D21'
							# findOne attempt
							err, result <- Attempt.findOne {
								course: ObjectId res.locals.course._id
								# assignment: {$in: assignments}
								author: ObjectId req.session.uid
								_id: ObjectId req.params.attempt
							} .populate('assignment').populate('author').exec
							res.locals.attempts = result
							done!
						else if req.params.assign?
							# winston.info 'D22'
							# find attempts
							err, result <- Attempt.find {
								course: ObjectId res.locals.course._id
								# assignment: {$in: assignments}
								author: ObjectId req.session.uid
							} .populate('assignment').populate('author').exec
							res.locals.attempts = result
							done!
						else
							done!
					else
						done!
			]
			next!
		.get (req, res, next)->
			# winston.info util.inspect {
			# 	course: res.locals.course
			# 	assignments: res.locals.assignments
			# 	attempts: res.locals.attempts
			# }
			# winston.info 'E'
			# winston.info 'query::action',req.query.action
			async.parallel [
				(done)->
					if !req.query.action?
						if !req.params.assign?
							# show list of assignments by title
							res.render 'assignments'
				(done)->
					if !req.query.action?
						if req.params.assign?
							if req.params.attempt?
								# show attempt
								res.render 'assignments', {+attempt}
							else
								# show assignment details & attempt field
								res.render 'assignments', {+view}
				(done)->
					if req.query.action?
						next! # don't assume action, continue trying
			]
		.post (req, res, next)->
			# winston.info 'F'
			# handle new attempt
			if req.params.assign? && req.query.action is 'attempt'
				attempt = new Attempt {
					assignment: req.body.aid
					course: res.locals.course._id
					text: req.body.text
					school: app.locals.school
					author: ObjectId req.session.uid
				}
				err, attempt <- attempt.save
				/* istanbul ignore if */
				if err?
					winston.error err
					next new Error 'Mongo Error'
				else
					res.redirect "/#{req.params.course}/assignments/"+ encodeURIComponent req.params.assign
			else
				next! # not attempt
		.all (req, res, next)->
			# winston.info 'G'
			# to modify assignments you need to be faculty+
			res.locals.needs = 2
			app.locals.authorize req, res, next
		# EVERYTHING AFTER HERE IS FACULTY+ #
		.get (req, res, next)->
			# winston.info 'H'
			switch req.query.action
			| 'new'
				res.render 'assignments' {+create}
			| 'edit'
				res.render 'assignments' {+edit}
			| 'delete'
				res.render 'assignments' {+del}
			| _
				next! # don't assume action
		.put (req, res, next)->
			# winston.info 'I'
			# handle edit assignment
			switch req.query.action
			| 'edit'
				if !req.body.aid? || !req.body.title? || !req.body.text? || !req.body.tries? # double check require fields exist
					res.status 400
					res.render 'assignments' {+edit, body: req.body, success:'no', action:'edit'}
				else
					res.locals.start = new Date(req.body.opendate+" "+req.body.opentime)
					res.locals.end = new Date(req.body.closedate+" "+req.body.closetime)
					assign = {
						title: encodeURIComponent req.body.title
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
					if !moment(res.locals.end).isValid!
						# winston.info 'I3'
						delete assign.end
					err, assignment <- Assignment.findOneAndUpdate {
						'_id': ObjectId req.body.aid
						'school': app.locals.school
						'course': ObjectId res.locals.course._id
						# don't check for author as me might not be...
					}, assign
					if err?
						# winston.info 'I4'
						winston.error err
						next new Error 'Mongo Error'
					else
						# winston.info 'I5'
						res.redirect "/#{req.params.course}/assignments/"+ encodeURIComponent req.params.assign
			| _
				next! # don't assume action
		.post (req, res, next)->
			# winston.info 'J'
			# handle new assignment
			switch req.query.action
			| 'new'
				if !req.body.title? || !req.body.text? || !req.body.tries? # double check require fields exist
					res.status 400
					res.render 'assignments' {+create, body: req.body, success:'no', action:'edit'}
				else
					# winston.info 'J1'
					res.locals.start = new Date req.body.opendate+" "+req.body.opentime
					res.locals.end = new Date req.body.closedate+" "+req.body.closetime
					assign = {
						title: encodeURIComponent req.body.title
						text: req.body.text
						start: res.locals.start
						end: res.locals.end
						tries: req.body.tries
						allowLate: if req.body.allowLate is "yes" then true else false
						totalPoints: req.body.total
						# unchangeable
						author: ObjectId req.session.uid
						course: res.locals.course._id
						school: app.locals.school
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
						res.status 302 .redirect "/#{req.params.course}/assignments/"+ encodeURIComponent req.body.title
			| 'grade'
				# winston.info 'J2'
				if !req.body.points? || !req.body.aid? # double check require fields exist
					res.status 400
					res.render 'assignments' {+create, assignments: [req.body], -success, action:'edit'}
				else
					err, attempt <- Attempt.findOneAndUpdate {
						'school': app.locals.school
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
						res.status 302 .redirect "/#{req.params.course}/assignments/"+ encodeURIComponent(req.params.assign) +"/"+ attempt._id.toString()
			| _
				next! # don't assume action
		.delete (req, res, next)->
			# winston.info 'K'
			# handle delete assignment (faculty+)
			switch req.query.action
			| 'delete'
				err, attempts <- Attempt.remove {
					'assignment': ObjectId req.body.aid
					'school': app.locals.school
					'course': ObjectId res.locals.course._id
				}
				# winston.info 'deleted:',attempts
				if err?
					winston.error err
					next new Error 'Mongo Error'
				else
					err, assignments <- Assignment.remove {
						'_id': ObjectId req.body.aid
						'school': app.locals.school
						'course': ObjectId res.locals.course._id
					}
					# winston.info 'deleted:',assignments
					if err?
						winston.error err
						next new Error 'Mongo Error'
					else
						res.status 302 .redirect "/#{req.params.course}/assignments"
			| 'deleteall'
				# pluck only _id off of all assignments
				plucked = _.pluck res.locals.assignments, '_id'
				# winston.info 'pluck', plucked
				# winston.info 'typeof plucked', typeof plucked.0
				# convert all assignment._id's to ObjectIds
				assignments = _.map plucked, ObjectId
				# winston.info 'mapped', assignments
				err, attempts <- Attempt.remove {
					'assignment': {$in: assignments}
					'school': app.locals.school
					'course': ObjectId res.locals.course._id
				}
				# winston.info 'deleted:',attempts
				if err?
					winston.error err
					next new Error 'Mongo Error'
				else
					err, assignments <- Assignment.remove {
						'_id': {$in: assignments}
						'school': app.locals.school
						'course': ObjectId res.locals.course._id
					}
					# winston.info 'deleted:',assignments
					if err?
						winston.error err
						next new Error 'Mongo Error'
					else
						res.status 302 .redirect "/#{req.params.course}/assignments"
			| _
				next! # don't assume action
