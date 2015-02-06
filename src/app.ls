#!/usr/bin/env lsc
# ``#!/usr/bin/env node`` # uncomment for lsc to node

if !process.env.cookie?
	console.log 'REQUIRES COOKIE SECRET'
	process.exit 1
if !process.env.school?
	console.log 'REQUIRES SCHOOL NAME'
	process.exit 1
if !process.env.mongo? and !process.env.MONGOURL?
	console.log 'mongo env undefined\ntrying localhost anyway...'

# Imports/Variables
require! {
	'async'
	'body-parser'
	'compression' # nginx gzip
	'express' # router
	'express-partial-response'
	'express-session' # session
	'fs-extra' # only if needed
	'method-override'
	'mongoose'
	'multer'
	'serve-static' # nginx static
	'swig' # templates
	'uuid'
	'winston'
	'yargs' # --var val
}

app = module.exports = express!
fs = fsExtra

mongouser = if process.env.mongouser or process.env.MONGOUSER then ( process.env.mongouser || process.env.MONGOUSER )
mongopass = if process.env.mongopass or process.env.MONGOPASS then ( process.env.mongopass || process.env.MONGOPASS )

# mongoose.connect (process.env.mongo || process.env.MONGOURL || 'mongodb://localhost/smrtboard') { 'auth': }
schemas = require('./schemas')(mongoose)
db = mongoose.connection
if mongouser? && mongopass?
	db.open (process.env.mongo||process.env.MONGOURL||'mongodb://localhost/smrtboard'), { 'user': mongouser, 'pass': mongopass }
else
	db.open (process.env.mongo||process.env.MONGOURL||'mongodb://localhost/smrtboard')
db.on 'disconnect', -> db.connect!
db.on 'error', console.error.bind console, 'connection error:'
err, something <- db.once 'open'
if err
	winston.info 'db:err: ' + err
winston.info 'db:something: ' + something

School = mongoose.model 'School', schemas.School
err,school <- School.find { name:process.env.school }
if err?
	winston.error 'school:find ' + util.inspect err
if !school[0]? # if none
	winston.info 'creating new school '+process.env.school
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
	.use '/static' serveStatic './static'
	.use '/assets' serveStatic './static'
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
	# .use csurf {
	# 	secretLength: 32
	# 	saltLength: 10
	# }
	# compress large files
	.use compression!

# Custom Middleware
app
	.use (req, res, next)->
		async.parallel [
			!->
				if res.locals.csrfToken?
					res.locals.csrfToken = req.csrfToken!
			!->
				if req.session.auth? # check if auth exists
					res.locals.auth = req.session.auth # save auth level for template
			!->
				next!
		]

# App Functions/Variables/Modules
app
	# variables
	..locals.recaptchaPrivateKey = process.env.RECAPKEY
	# modules
	..locals.fs = fsExtra
	..locals.async = async
	..locals.winston = winston
	..locals.db = db
	..locals.school = process.env.school
	..locals.models = {
		school: school
		Student: mongoose.model 'Student' schemas.Student
		Faculty: mongoose.model 'Faculty' schemas.Faculty
		Admin: mongoose.model 'Admin' schemas.Admin
		Course: mongoose.model 'Course' schemas.Course
		Required: mongoose.model 'Req' schemas.Req
		Attempt: mongoose.model 'Attempt' schemas.Attempt
		Grade: mongoose.model 'Grade' schemas.Grade
		Thread: mongoose.model 'Thread' schemas.Thread
		Post: mongoose.model 'Post' schemas.Post
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
	# disable template cache
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
	if process.env.port? or process.env.PORT? or yargs.argv.http? or yargs.argv.port? # assure one of the settings were given
		port = (process.env.port or process.env.PORT) or (yargs.argv.http or yargs.argv.port)
		winston.info 'Server started on port ' + port + ' at ' + new Date Date.now!
		server = app.listen port
	else
		winston.error 'No port/socket specified please use HTTP or PORT environment variable'
		process.exit 1
else
	app.locals.testing = true
	# silence all logging on testing
	winston.remove winston.transports.Console
	require('./test')(app)
