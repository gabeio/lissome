/*
	this module is meant only to load for testing.
*/
/* istanbul ignore next only for testing anyway */
module.exports = (app)->
	require! {
		'mongoose'
		'winston'
	}
	ObjectId = mongoose.Types.ObjectId
	User = app.locals.models.User
	Course = app.locals.models.Course
	Post = app.locals.models.Post
	Assignment = app.locals.models.Assignment
	# winston = app.locals.winston
	winston.warn 'TESTING MODE\nIF YOU SEE THIS MESSAGE THERE IS SOMETHING WRONG!!!'
	app
		..route '/test/:action/:more?'
		.all (req, res, next)->
			switch req.params.action
			| 'getauth'
				res.status 200 .send req.session.auth
			| 'getroot'
				req.session.auth = 4
				res.status 200 .send 'ok'
			| 'getadmin'
				req.session.auth = 3
				res.status 200 .send 'ok'
			| 'getfaculty'
				req.session.auth = 2
				res.status 200 .send 'ok'
			| 'getstudent'
				req.session.auth = 1
				res.status 200 .send 'ok'
			| 'getaid'
				err, result <- Course.findOne {
					'id': req.params.more
					'school': app.locals.school
				}
				if err
					winston.error 'test:course:findOne:blog', err
					next new Error 'INTERNAL'
				else
					err, result <- Assignment.find {
						'course': ObjectId(result._id)
						'title': req.query.title
					}
					if err
						winston.error 'test:course:find:assignment', err
						next new Error 'INTERNAL'
					else
						res.json result
			| 'getpid'
				err, result <- Course.findOne {
					'id': req.params.more
					'school': app.locals.school
				}
				if err
					winston.error 'test:course:findOne:blog', err
					next new Error 'INTERNAL'
				else
					res.locals.course = result
					err, result <- Post.find {
						'course': ObjectId(res.locals.course._id)
						'type': 'blog'
					}
					if err
						winston.error 'test:course:find:post', err
						next new Error 'INTERNAL'
					else
						res.json result
			| 'postblog'
				err, result <- Course.findOne {
					'id': req.body.course
					'school': app.locals.school
				}
				if err
					winston.error 'course:findOne:blog:auth3', err
					next new Error 'INTERNAL'
				else
					if !result? or result.length is 0
						next new Error 'NOT FOUND'
					else
						res.locals.course = result
						authorUsername = req.session.username
						authorName = req.session.firstName+" "+req.session.lastName
						post = new Post {
							title: encodeURIComponent req.body.title
							text: req.body.text
							# files: req.body.files
							author: ObjectId req.session.uid
							authorName: authorName
							authorUsername: authorUsername
							tags: []
							type: 'blog'
							school: app.locals.school
							course: ObjectId res.locals.course._id
						}
						err, post <- post.save
						res.json post
			| _
				...
