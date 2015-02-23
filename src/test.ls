/*
	this module is meant only to load for testing.
*/
/* istanbul ignore next only for testing anyway */
module.exports = (app)->
	require! {
		'mongoose'
		'winston'
	}
	User = app.locals.models.User
	Course = app.locals.models.Course
	Post = app.locals.models.Post
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
						'course': mongoose.Types.ObjectId(res.locals.course._id)
						'type': 'blog'
					}
					if err
						winston.error 'test:course:find:post', err
						next new Error 'INTERNAL'
					else
						res.json result
			| _
				...
