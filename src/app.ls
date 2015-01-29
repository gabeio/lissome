#!/usr/bin/env lsc
# ``#!/usr/bin/env node`` # uncomment for lsc to node
if !process.env.cookie?
	console.log 'REQUIRES COOKIE SECRET'
	process.exit 1
if !process.env.school?
	console.log 'REQUIRES SCHOOL NAME'
	process.exit 1
# Imports/Variables
require! {
	'async'
	'body-parser'
	'compression' # nginx gzip
	'csurf'
	'express' # router
	'express-partial-response'
	'express-session' # session
	'fs-extra' # only if needed
	'method-override'
	'mongoose'
	'multer'
	'serve-static' # nginx static
	'swig' # templates
	'winston'
	'yargs' # --var val
}
app = module.exports = express!
fs = fsExtra
mongoose.connect (process.env.MONGO || 'mongodb://localhost/smrtboard')
db = mongoose.connection
db.on 'error', console.error.bind console, 'connection error:'
<- db.once 'open'
schemas = require('./schemas')(mongoose)
School = mongoose.model 'School', schemas.School
school = new School {
	name: process.env.school
}
err, school <- school.save

# App Settings/Middleware
app
	# needs to come first MIGHT NOT WORK...
	# .use method-override
	# sessions
	.use expressSession {
		secret: process.env.cookie
		-resave
		+saveUninitialized
		cookie: {
			path: '/'
			+httpOnly
		}
	}
	# hide what we are made of
	.disable 'x-powered-by'
	# set extention of templates to html to render in swig
	.engine 'html' swig.renderFile
	# set extention of templates to html
	.set 'view engine' 'html'
	# .set 'views' __dirname + '/NOTviews' # /views by default
	# static assets (html,js,css)
	.use '/static' serveStatic './static' # comment out when in production or cache server infront
	# body parser
	.use bodyParser.urlencoded {
		-extended
	}
	.use bodyParser.json!
	# .use bodyParser.text! # idk
	# .use bodyParser.raw! # idk
	# multipart body parser
	.use multer { # requires: enctype="multipart/form-data"
		dest: './uploads/'
		limits:
			fileSize: 10000000
			files: 10
		-includeEmptyFields
		-inMemory
	}
	# Cross Site Request Forgery
	.use csurf {
		secretLength: 32
		saltLength: 10
	}
	# compress large files
	.use compression!

# Custom Middleware
app
	.use (req, res, next)->
		async.parallel [
			!->
				res.locals.csrfToken = req.csrfToken!
			!->
				next!
		]

# App Functions/Variables/Modules
app
	# functions
	..locals.authorized = (req, res, next)->
		# session TTL = 1 day
		if req.session.admin is true
			next!
		else
			next new Error 'UNAUTHORIZED'
	# variables
	..locals.recaptchaPrivateKey = process.env.RECAPKEY
	# modules
	..locals.fs = fsExtra
	..locals.async = async
	..locals.winston = winston
	..locals.models = {
		school: school
		student: mongoose.model 'Student', schemas.Student
		teacher: mongoose.model 'Teacher', schemas.Teacher
		admin: mongoose.model 'Admin', schemas.Admin
		course: mongoose.model 'Course', schemas.Course
		required: mongoose.model 'Req', schemas.Req
		attempt: mongoose.model 'Attempt', schemas.Attempt
		grade: mongoose.model 'Grade', schemas.Grade
		thread: mongoose.model 'Thread', schemas.Thread
		post: mongoose.model 'Post', schemas.Post
	}
	# errors
	# ..locals.err = {
	# 	'NOT FOUND': new Error
	# }

# Production Switch
switch process.env.NODE_ENV
| 'production'
	# production run
	winston.info "Production Mode"
| _
	# development/other run
	winston.info "Development Mode/Unknown Mode"
	require! {
		util
	}
	app.set 'view cache' false
	swig.setDefaults { -cache }
	app.locals.util = if util? then util
	app.use (req, res, next)->
		async.parallel [
			!->
				thestr = req.method+"\t"+req.url
				if req.xhr
					thestr += "\tXHR"
				winston.info thestr
			!->
				next!
		]

# Attach base
require('./base')(app)

/* istanbul ignore next */
if !module.parent # assure this file is not being run by a different file
	if process.env.HTTP? or process.env.PORT? or yargs.argv.http? or yargs.argv.port? # assure one of the settings were given
		port = (process.env.HTTP or process.env.PORT) or (yargs.argv.http or yargs.argv.port)
		winston.info 'Server started on port ' + port + ' at ' + new Date Date.now!
		server = app.listen port
	else
		winston.error 'No port/socket specified please use HTTP or PORT environment variable'
		process.exit 1
else
	winston.warn "TESTING MODE MODE IS *NOT* SAFE."
	# for testing
	
	# silence all logging on testing
	winston.remove winston.transports.Console
	
	# all of the following routes only exists in testing
	app
		..route '/get/test/on/:something'
		.get (req, res, next)->
			switch req.params.something
			| 'csrf' # get csrfToken
				res.send res.locals.csrfToken
			| 'admin' # get session.admin
				res.send util.inspect req.session.admin
			| _
				res.send 0
		..route '/post/test/on/:something'
		.post (req, res, next)->
			switch req.params.something
			| 'admin'
				req.session.admin = true
				res.send 'ok'
			| _
				res.send 0
