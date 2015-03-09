module.exports = (app)->
	require! {
		'async'
		'lodash'
		'moment'
		'mongoose'
		'uuid'
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
		..route '/:course/assignments/:unique?/:attempt?' # query :: action(new|edit|delete|grade|list|attempt) /:student?
		.all (req, res, next)->
			# check if action is defined
			if req.query.action?
				console.log 'a'
				req.query.action = req.query.action.toLowerCase! # lowercase
				# check if action is faculty+ action
				if req.query.action in ['new','edit','delete','grade','list','view']
					console.log 'b'
					next!
				else
					console.log 'b2'
					next 'route'
			else
				console.log 'a2'
				next 'route'
		.all (req, res, next)->
			# check auth level
			res.locals.needs = 2
			app.locals.authorize req, res, next
		.all (req, res, next)->
			# get course
			res.locals.on = 'assignments'
			<- async.parallel [
				(done)->
					if req.session.auth is 3
						err, result <- Course.findOne {
							'id': req.params.course
							'school': app.locals.school
						} .populate('students').exec
						/* istanbul ignore if */
						if err
							winston.error 'course:findOne:assignments:auth3', err
							next new Error 'INTERNAL'
						else
							/* istanbul ignore if */
							if !result? or result.length is 0
								next new Error 'NOT FOUND'
							else
								res.locals.course = result
								done!
					else
						done!
				(done)->
					if req.session.auth is 2
						err, result <- Course.findOne {
							'id': req.params.course
							'school': app.locals.school
							'faculty': ObjectId req.session.uid
						} .populate('students').exec
						/* istanbul ignore if */
						if err
							winston.error 'course:findOne:assignments:auth2', err
							next new Error 'INTERNAL'
						else
							/* istanbul ignore if */
							if !result? or result.length is 0
								next new Error 'NOT FOUND'
							else
								res.locals.course = result
								done!
					else
						done!
			]
			next!
		.all (req, res, next)->
			# get assignment(s) if unique identifier is defined
			if req.params.unique? and req.params.unique isnt ""
				# find assignment(s) of a course w/ title
				err, assignments <- Assignment.find {
					title: encodeURIComponent req.params.unique
					course: ObjectId res.locals.course._id
					school: app.locals.school
				} .populate('author').exec
				if assignments?
					res.locals.assignments = assignments
					next!
				else
					res.send 'assignment doesn\'t exist'
			else
				console.log 'd'
				next!
		# .get (req, res, next)->
		# 	err, assignments <- Assignment.find {
		# 		course: ObjectId res.locals.course._id
		# 	} .populate('author').exec
		# 	if err
		# 		winston.error 'assignments:find', err
		# 		next new Error 'INTERNAL'
		# 	else
		# 		res.locals.assignments = assignments
		# 		next!
		.get (req, res, next)->
			switch req.query.action
			| 'view' # view an attempt
				console.log 'attempt view'
				# pluck only _id off of all assignments
				# plucked = _.pluck res.locals.assignments, '_id'
				# console.log 'pluck', plucked
				# console.log 'typeof plucked', typeof plucked.0
				# convert all assignment._id's to ObjectIds
				# assignments = _.map plucked, ObjectId
				# console.log 'mapped', assignments
				# console.log 'typeof mapped', typeof assignments.0
				err, attempt <- Attempt.findOne {
					_id: ObjectId req.params.attempt
					# assignment: {$in: assignments}
					course: res.locals.course._id
					# author: ObjectId req.params.student
				} .populate('assignment').populate('author').exec
				if err
					winston.error 'attempt find', err
					next new Error 'INTERNAL'
				else
					console.log 'attempt',attempt
					res.locals.attempt = attempt
					next!
			| 'list' # view assignment/view student's names who attempted it
				console.log 'attempt view'
				# pluck only _id off of all assignments
				plucked = _.pluck res.locals.assignments, '_id'
				console.log 'pluck', plucked
				console.log 'typeof plucked', typeof plucked.0
				# convert all assignment._id's to ObjectIds
				assignments = _.map plucked, ObjectId
				console.log 'mapped', assignments
				console.log 'typeof mapped', typeof assignments.0
				# find all attempts of assignments
				err, attempts <- Attempt.find {
					assignment: {$in: assignments}
				} .populate('assignment').populate('author').exec
				if err
					winston.error 'attempt find'
					next new Error 'INTERNAL'
				else
					res.locals.attempts = attempts
					next!
			| _
				console.log 'NEXT!'
				next!
		.get (req, res, next)->
			res.locals.assign = true
			switch req.query.action
			| 'new'
				res.render 'assignments', { +create, on:'newassignment', action:'created', success:req.query.success }
			| 'edit'
				res.render 'assignments', { +edit, on:'editassignment', action:'updated', success:req.query.success, body:res.locals.assignment }
			| 'delete'
				res.render 'assignments', { +del, on:'deleteassignment', action:'deleted', success:req.query.success }
			| 'list'
				res.render 'assignments', { +list, on:'listattempts' }
			| 'view'
				res.render 'assignments', { +viewattempt, on:'viewattempt' }
			| 'grade'
				res.render 'assignments', { +grade, on:'gradeassignment', action:'graded', success:req.query.success }
		.post (req, res, next)->
			if req.query.action in ['new','grade'] # assure it should be a post
				<- async.parallel [
					->
						if req.query.action is "new"
							assignment = new Assignment {
								author: ObjectId req.session.uid
								# authorName: req.session.firstName+" "+req.session.lastName
								# authorUsername: req.session.username
								course: ObjectId res.locals.course._id
								title: encodeURIComponent req.body.title
								start: new Date(req.body.opendate+" "+req.body.opentime)
								end: new Date(req.body.closedate+" "+req.body.closetime)
								tries: req.body.tries
								allowLate: if req.body.late is "yes" then true else false
								totalPoints: req.body.total
								school: app.locals.school
								# OPTIONAL
								text: req.body.text
								# files: Buffer # Require's file(s)?
							}
							err, assignment <- assignment.save
							if err
								winston.error 'new assignment save', err
								next new Error ''
							else
								res.render 'assignments', {+create, on:'newassignment', action:'created', success:'yes' }
					->
						if req.query.action is "grade"
							...
				]
			else
				next new Error 'INTERNAL'
		.put (req, res, next)->
			if req.query.action in ['edit'] # assure it should be a put
				<- async.parallel [
					->
						if req.query.action is 'edit'
							updatedValues = {}
							console.log 'update', req.body
							res.locals.start = new Date(req.body.opendate)
							res.locals.end = new Date(req.body.closedate)
							console.log 'open date', if moment(res.locals.start).isValid! then res.locals.start else void
							console.log 'close date', if moment(res.locals.end).isValid! then res.locals.end else void
							updatedValues.title = encodeURIComponent req.body.title
							updatedValues.text = req.body.text
							updatedValues.allowLate = if req.body.late is "yes" then true else false # default false
							updatedValues.tries = if req.body.tries? then req.body.tries else 1 # default 1
							if moment(res.locals.start).isValid!
								updatedValues.start = res.locals.start
							if moment(res.locals.end).isValid!
								updatedValues.end = res.locals.end
							res.locals.start = new Date(req.body.opendate+" "+req.body.opentime)
							res.locals.end = new Date(req.body.closedate+" "+req.body.closetime)
							if moment(res.locals.start).isValid!
								updatedValues.start = res.locals.start
							if moment(res.locals.end).isValid!
								updatedValues.end = res.locals.end
							if req.body.total?
								updatedValues.totalPoints = req.body.total
							err, result <- Assignment.findOneAndUpdate {
								'course': res.locals.course._id
								'_id': ObjectId req.body.aid
							},updatedValues
							console.log 'now',result
							if err
								winston.error 'assignments:update', err
								next new Error 'INTERNAL'
							else
								res.redirect "/#{res.locals.course.id}/assignments/"+encodeURIComponent(req.body.title)+"?action=edit&success=yes"
								# res.render 'assignments', { +edit, on:'editassignment', action:'updated', success:'yes' }
				]
			else
				next new Error 'INTERNAL'
		.delete (req, res, next)->
			if req.query.action in ['delete'] # assure it should be a delete
				<- async.parallel [
					->
						if req.query.action is 'delete'
							err, result <- Assignment.findOneAndRemove {
								course: res.locals.course._id
								_id: ObjectId req.body.aid
							}
							if err
								winston.error 'assignments:delete', err
								next new Error 'INTERNAL'
							else
								res.redirect "/#{res.locals.course.id}/assignments/#{req.body.title}?action=delete?success=yes"
								# res.render 'assignments', { +edit, on:'deleteassignment', action:'deleted', success:'yes' }
				]
			else
				next new Error 'INTERNAL'

		..route '/:course/assignments/:unique?/:version?' # query action(submit)
		.all (req, res, next)->
			console.log req.url, 'STUDENT'
			res.locals.needs = 1
			app.locals.authorize req, res, next
		.all (req, res, next)->
			res.locals.on = 'assignments'
			<- async.parallel [
				(done)->
					if req.session.auth is 3
						err, result <- Course.findOne {
							'id': req.params.course
							'school': app.locals.school
						}
						/* istanbul ignore if */
						if err
							winston.error 'course:findOne:assignments:auth3', err
							next new Error 'INTERNAL'
						else
							/* istanbul ignore if */
							if !result? or result.length is 0
								next new Error 'NOT FOUND'
							else
								res.locals.course = result
								done!
					else
						done!
				(done)->
					if req.session.auth is 2
						err, result <- Course.findOne {
							'id': req.params.course
							'school': app.locals.school
							'faculty': ObjectId req.session.uid
						}
						/* istanbul ignore if */
						if err
							winston.error 'course:findOne:assignments:auth2', err
							next new Error 'INTERNAL'
						else
							/* istanbul ignore if */
							if !result? or result.length is 0
								next new Error 'NOT FOUND'
							else
								res.locals.course = result
								done!
					else
						done!
				(done)->
					if req.session.auth is 1
						err, result <- Course.findOne {
							'id': req.params.course
							'school': app.locals.school
							'students': ObjectId req.session.uid
						}
						/* istanbul ignore if */
						if err
							winston.error 'course:findOne:assignments:auth1', err
							next new Error 'INTERNAL'
						else
							/* istanbul ignore if */
							if !result? or result.length is 0
								next new Error 'NOT FOUND'
							else
								res.locals.course = result
								done!
					else
						done!
			]
			next!
		.all (req, res, next)->
			err <- async.parallel [
				(done)->
					err, results <- Assignment.find {
						course: ObjectId res.locals.course._id
					}
					if results.length > 0
						res.locals.assignments = _.sortBy results, 'title'
					else
						res.locals.assignments = results
					done err
				(done)->
					err, results <- Attempt.find {
						course: ObjectId res.locals.course._id
						author: ObjectId req.session.uid
					}
					if results.length > 0
						res.locals.attempts = _.sortBy results, 'assignment'
					else
						res.locals.attempts = results
					done err
			]
			if err
				winston.error 'assignment/attempt:find', err
			else
				next!
		.get (req, res, next)->
			if req.params.unique? and req.params.unique isnt ""
				err, assignment <- Assignment.findOne {
					course: ObjectId res.locals.course._id
					title: req.params.unique
				} .populate('author').exec
				if err
					winston.error 'assignments:find', err
					next new Error 'INTERNAL'
				else
					res.locals.assignment = assignment
					res.render 'assignments', { +viewassignment, on:'assignment' }
			else
				err, assignments <- Assignment.find {
					course: ObjectId res.locals.course._id
				}
				if err
					winston.error 'assignments:find', err
					next new Error 'INTERNAL'
				else
					res.locals.assignments = assignments
					res.render 'assignments'
		.post (req, res, next)->
			if req.query.action is "submit" and req.body.aid? and req.body.aid isnt ""
				assignment = _.filter res.locals.assignments, (input)->
					return if input._id.toString! is req.body.aid then input
				.0
				attempts = _.filter res.locals.attempts, (input)->
					return if input.assignment.toString! is req.body.aid then input
				if req.query.action is "submit" and assignment.tries > attempts.length # only if you have more tries
					attempt = new Attempt {
						author: ObjectId req.session.uid
						# authorName: req.session.firstName+" "+req.session.lastName
						# authorUsername: req.session.username
						attempt: attempts.length+1
						assignment: ObjectId req.body.aid
						course: ObjectId res.locals.course._id
						text: req.body.text
						# files: Buffer # student attempt file(s)?
						school: app.locals.school
					}
					err,attempt <- attempt.save
					if err
						winston.error 'attempt:save', err
						next new Error 'INTERNAL'
					else
						res.redirect '/'
						# res.render 'assignments', { submitted: 'yes' }
				else
					next new Error 'NO MORE ATTEMPTS ALLOWED'
			else
				next!
