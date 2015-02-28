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
		..route '/:course/assignments/:action(new|edit|delete|grade)/:unique?/:student?/:version?'
		.all (req, res, next)->
			res.locals.needs = 2
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
			]
			next!
		.all (req, res, next)->
			if req.method.toLowerCase! isnt 'get' and req.params.unique? and req.params.unique isnt ""
				err, result <- Assignment.findOne {
					title: req.params.unique
					course: ObjectId res.locals.course._id
					school: app.locals.school
				}
				if result.length is 0
					res.render '/'
				else
					next!
			else
				next!
		.get (req, res, next)->
			err, result <- Assignment.find {
				course: ObjectId res.locals.course._id
			}
			if err
				winston.error 'assignments:find', err
				next new Error 'INTERNAL'
			else
				res.locals.assignments = result
				# if result.length is 0
				next!
		.get (req, res, next)->
			switch req.params.action
			| 'new'
				res.render 'assignments', { +create, on:'newassignment' }
			| 'edit'
				res.render 'assignments', { +edit }
			| 'delete'
				res.render 'assignments', { +del }
			| 'grade'
				res.render 'assignments', { +grade }
		.post (req, res, next)->
			<- async.parallel [
				->
					if req.params.action is "new"
						res.redirect "/#{res.locals.course.id}/assignments"
						# res.render 'assignments', { +create, stuff: req.body }
				->
					if req.params.action is "new"
						assignment = new Assignment {
							author: ObjectId req.session.uid
							authorName: req.session.firstName+" "+req.session.lastName
							authorUsername: req.session.username
							course: ObjectId res.locals.course._id
							title: req.body.title
							start: req.body.open
							end: req.body.close
							tries: req.body.tries
							allowLate: if req.body.late is "yes" then true else false
							totalPoints: req.body.total
							school: app.locals.school
							# OPTIONAL
							text: req.body.text
							# files: Buffer # Require's file(s)?
						}
						err, assignment <- assignment.save
						if err?
							winston.error 'new assignment save', err
			]
		.put (req, res, next)->
			...
		.delete (req, res, next)->
			...

		..route '/:course/assignments/:action(submit)?/:unique?/:version?'
		.all (req, res, next)->
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
				err, results <- Assignment.find {
					course: ObjectId res.locals.course._id
					title: req.params.unique
				}
				if err
					winston.error 'assignments:find', err
					next new Error 'INTERNAL'
				else
					res.locals.assignments = results
					res.render 'assignments', { +work, assignment:req.params.unique, on:'assignment' }
			else
				err, results <- Assignment.find {
					course: ObjectId res.locals.course._id
				}
				if err
					winston.error 'assignments:find', err
					next new Error 'INTERNAL'
				else
					res.locals.assignments = results
					res.render 'assignments'
		.post (req, res, next)->
			if req.params.action is "submit" and req.body.aid? and req.body.aid isnt ""
				# console.log 'aid', req.body.aid
				# for assignment in res.locals.assignments
				# 	console.log "#{assignment._id}"
				# 	if ObjectId(req.body.aid) is assignment['_id']
				# 		console.log 'there is'
				assignment = _.filter res.locals.assignments, (input)->
					return if input._id.toString! is req.body.aid then input
				.0
				console.log assignment['tries']
				# console.log res.locals.attempts
				attempts = _.filter res.locals.attempts, (input)->
					return if input.assignment.toString! is req.body.aid then input
				console.log attempts
				# res.send '0'
				# return 0
				if req.params.action is "submit" and assignment.tries > attempts.length # only if you have more tries
					attempt = new Attempt {
						author: ObjectId req.session.uid
						authorName: req.session.firstName+" "+req.session.lastName
						authorUsername: req.session.username
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
						res.render 'assignments', { submitted: 'yes' }
				else
					next new Error 'NO MORE ATTEMPTS ALLOWED'
			else
				next!
