/*
	this module is meant only to load for testing.
*/
module.exports = exports = (app)->
	winston = app.locals.winston
	winston.warn 'IF YOU SEE THIS MESSAGE THERE IS SOMETHING WRONG!!!'
	app
		..route '/test/:action'
		.get (req, res, next)->
			switch req.params.action
			| 'getroot'
				req.session.auth = 4
			| 'getadmin'
				req.session.auth = 3
			| 'getfaculty'
				req.session.auth = 2
			| 'getstudent'
				req.session.auth = 1
			| _
				...