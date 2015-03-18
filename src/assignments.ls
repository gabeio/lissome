module.exports = (app)->
	require! {
		'async'
		'lodash'
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
		..route '/:course/assignments/:assign?/:attempt?' # query :: action(new|edit|delete|grade)
		.all (req, res, next)->
			# to be in course auth needs to be min = 1
			res.locals.needs = 1
			app.locals.authorize req, res, next
		.all (req, res, next)->
			# do for every request
			# get course_id
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
			# do for every request
			# get assign_id
			if req.params.assign? and req.params.assign isnt ""
				# findOne assignment
				err, result <- Assignment.findOne {
					title: req.params.unique
					course: ObjectId res.locals.course._id
					school: app.locals.school
				}

			else
				# find assignments
				err, result <- Assignment.find {
					title: req.params.unique
					course: ObjectId res.locals.course._id
					school: app.locals.school
				}
		.all (req, res, next)->
			# split student|faculty
			# get attempt_id
			<- async.parallel [
				(done)->
					# faculty+
					if req.session.auth >= 2
						if req.params.attempt? and req.params.attempt isnt ""
							# findOne attempt
							err, results <- Attempt.findOne {
								course: ObjectId res.locals.course._id
							}
							if err
								winston.error '', err
								next new Error 'INTERNAL'
							else
								if !result? or result.length is 0
									next new Error 'NOT FOUND'
								else
									res.locals.attempts = result
									done!
						else
							# find attempts
							err, results <- Attempt.find {
								course: ObjectId res.locals.course._id
							}
							if err
								winston.error '', err
								next new Error 'INTERNAL'
							else
								if !result? or result.length is 0
									next new Error 'NOT FOUND'
								else
									res.locals.attempts = result
									done!
				(done)->
					# student
					if req.session.auth is 1
						if req.params.attempt? and req.params.attempt isnt ""
							# findOne attempt
							err, results <- Attempt.findOne {
								course: ObjectId res.locals.course._id
								author: ObjectId req.session.uid
							}
							if err
								winston.error '', err
								next new Error 'INTERNAL'
							else
								if !result? or result.length is 0
									next new Error 'NOT FOUND'
								else
									res.locals.attempts = result
									done!
						else
							# find attempts
							err, results <- Attempt.find {
								course: ObjectId res.locals.course._id
								author: ObjectId req.session.uid
							}
							if err
								winston.error '', err
								next new Error 'INTERNAL'
							else
								if !result? or result.length is 0
									next new Error 'NOT FOUND'
								else
									res.locals.attempts = result
									done!
			]
			next!
		.get (req, res, next)->
			res.render 'assignments'
		.put (req, res, next)->
			# handle edit assignment
			...
		.post (req, res, next)->
			# handle new assignment
			...
		.post (req, res, next)->
			# handle new attempt
			...
		.delete (req, res, next)->
			# handle delete assignment (faculty+)
			...
