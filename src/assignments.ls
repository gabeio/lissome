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
		..route '/:course/assignments/:unique?/:student?/:version?' # query :: action(new|edit|delete|grade)
		.all (req, res, next)->
			req.query.action = req.query.action.toLowerCase!
			if req.query.action in ['new','edit','delete','grade']
				next!
			else
				next 'route'
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
			err, assignments <- Assignment.find {
				course: ObjectId res.locals.course._id
			}
			if err
				winston.error 'assignments:find', err
				next new Error 'INTERNAL'
			else
				res.locals.assignments = assignments
				next!
		.get (req, res, next)->
			switch req.query.action
			| 'new'
				res.render 'assignments', { +create, on:'newassignment', action:'created', success:req.query.success }
			| 'edit'
				res.render 'assignments', { +edit, on:'editassignment', action:'updated', success:req.query.success }
			| 'delete'
				res.render 'assignments', { +del, on:'deleteassignment', action:'deleted', success:req.query.success }
			| 'grade'
				res.render 'assignments', { +grade, on:'gradeassignment', action:'graded', success:req.query.success }
		.post (req, res, next)->
			if req.query.action in ['new','grade'] # assure it should be a post
				<- async.parallel [
					->
						if req.query.action is "new"
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
							err, result <- Assignment.findOneAndUpdate {
								'course': res.locals.course._id
								'_id': ObjectId req.body.aid
							},{
								'title': req.body.title
								'body': req.body.body
							}
							if err
								winston.error 'assignments:update', err
								next new Error 'INTERNAL'
							else
								res.render 'assignments', { +edit, on:'editassignment', action:'updated', success:'yes' }
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
								res.render 'assignments', { +edit, on:'deleteassignment', action:'deleted', success:'yes' }
				]
			else
				next new Error 'INTERNAL'

		..route '/:course/assignments/:unique?/:version?' # query action(submit)
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
			...
			# if req.query.action is "submit" and req.body.aid? and req.body.aid isnt ""
			# 	assignment = _.filter res.locals.assignments, (input)->
			# 		return if input._id.toString! is req.body.aid then input
			# 	.0
			# 	attempts = _.filter res.locals.attempts, (input)->
			# 		return if input.assignment.toString! is req.body.aid then input
			# 	if req.query.action is "submit" and assignment.tries > attempts.length # only if you have more tries
			# 		attempt = new Attempt {
			# 			author: ObjectId req.session.uid
			# 			authorName: req.session.firstName+" "+req.session.lastName
			# 			authorUsername: req.session.username
			# 			attempt: attempts.length+1
			# 			assignment: ObjectId req.body.aid
			# 			course: ObjectId res.locals.course._id
			# 			text: req.body.text
			# 			# files: Buffer # student attempt file(s)?
			# 			school: app.locals.school
			# 		}
			# 		err,attempt <- attempt.save
			# 		if err
			# 			winston.error 'attempt:save', err
			# 			next new Error 'INTERNAL'
			# 		else
			# 			res.render 'assignments', { submitted: 'yes' }
			# 	else
			# 		next new Error 'NO MORE ATTEMPTS ALLOWED'
			# else
			# 	next!
