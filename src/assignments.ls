module.exports = (app)->
	require! {
		'async'
		'lodash'
		'mongoose'
		'uuid'
		'winston'
	}
	_ = lodash
	User = app.locals.models.User
	Course = app.locals.models.Course
	Post = app.locals.models.Post
	Assignment = app.locals.models.Assignment
	Attempt = app.locals.models.Attempt
	app
		..route '/:course/assignments/:action(new|edit|delete|grade)/:unique?/:version?'
		.all (req, res, next)->
			res.locals.needs = 2
			app.locals.authorize req, res, next
		.all (req, res, next)->
			res.locals.on = 'blog'
			<- async.parallel [
				(done)->
					if req.session.auth is 3
						err, result <- Course.findOne {
							'id': req.params.course
							'school': app.locals.school
						}
						/* istanbul ignore if */
						if err
							winston.error 'course:findOne:blog:auth3', err
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
							'faculty': mongoose.Types.ObjectId req.session.uid
						}
						/* istanbul ignore if */
						if err
							winston.error 'course:findOne:blog:auth2', err
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
		.get (req, res, next)->
			# Attempt.find {
			# 	author: mongoose.Types.ObjectId req.session.uid
			# 	assignment: { type: Schema.Types.ObjectId, +required, ref: 'Assignment' }
			# 	text: String # student attempt text
			# 	files: Buffer # student attempt file(s)?
			# 	school: { type: String, +required, ref: 'School' }
			# 	points: Number
			# 	grader: { type: Schema.Types.ObjectId, ref: 'User' } # teacher who submitted graded it
			# }
			res.render 'assignments'

		..route '/:course/assignments/:action(submit)?/:unique?/:version?'
		.all (req, res, next)->
			res.locals.needs = 1
			app.locals.authorize req, res, next
		.all (req, res, next)->
			res.locals.on = 'blog'
			<- async.parallel [
				(done)->
					if req.session.auth is 3
						err, result <- Course.findOne {
							'id': req.params.course
							'school': app.locals.school
						}
						/* istanbul ignore if */
						if err
							winston.error 'course:findOne:blog:auth3', err
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
							'faculty': mongoose.Types.ObjectId req.session.uid
						}
						/* istanbul ignore if */
						if err
							winston.error 'course:findOne:blog:auth2', err
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
							'students': mongoose.Types.ObjectId req.session.uid
						}
						/* istanbul ignore if */
						if err
							winston.error 'course:findOne:blog:auth1', err
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
		.get (req, res, next)->
			# Attempt.find {
			# 	author: mongoose.Types.ObjectId req.session.uid
			# 	assignment: { type: Schema.Types.ObjectId, +required, ref: 'Assignment' }
			# 	text: String # student attempt text
			# 	files: Buffer # student attempt file(s)?
			# 	school: { type: String, +required, ref: 'School' }
			# 	points: Number
			# 	grader: { type: Schema.Types.ObjectId, ref: 'User' } # teacher who submitted graded it
			# }
			res.render 'assignments'
