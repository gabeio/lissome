#!/usr/bin/env lsc
# ``#!/usr/bin/env node`` # uncomment for lsc to node

# Imports/Variables
require! {
	# 'jsondown' # json files/ if needed
	# 'memdown' # in mem only/ if needed
	# 'mongoose' # only if needed
	'async'
	'body-parser'
	'compression' # nginx gzip
	'cookie-parser'
	'csurf'
	'express' # router
	'express-partial-response'
	'express-session' # session
	'fs-extra' # only if needed
	'leveldown'
	'levelup'
	'method-override'
	'multer'
	'serve-static' # nginx static
	'swig' # templates
	'winston'
	'yargs' # --var val
}
app = module.exports = express!
fs = fsExtra

# Setup DB
db = app.locals.db = levelup './db' { db: leveldown }

# App Settings/Middleware
app
	# needs to come first MIGHT NOT WORK...
	# .use method-override
	# sessions
	.use expressSession {
		secret: fs.readFileSync 'secret.key' \utf-8
		-resave
		+saveUninitialized
		cookie: {
			path: '/'
			+httpOnly
		}
	}
	# hide what we are made of
	.disable 'x-powered-by'
	# swig template setup
	# set extention of templates to html
	.engine 'html' swig.renderFile
	# set extention of templates to html
	.set 'view engine' 'html'
	# .set 'views' __dirname + '/NOTviews' # /views by default
	# static assets (html,js,css)
	.use '/static' serveStatic './static' # comment out when in production or cache server infront
	# body parser
	.use bodyParser.urlencoded { -extended } # standard (angular?)
	.use bodyParser.json! # json (angular?)
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
	winston.info "Development Mode"
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

# Error Catching
app
	..use (err, req, res, next)->
		async.parallel [
			!->
				# ALWAYS LOG
				winston.error 'error: ' + err + '\turl: ' + req.url
			!->
				if err?
					if err.code is 'EBADCSRFTOKEN'
						res.status 403 .send 'Bad Request' #.render 'error' {err:'Bad Request'}
					else
						# console.log err.message
						switch err.message
						| 'NOT FOUND'
							res.status 404 .render 'error' { err:'Not Found' }
						| 'NOT XHR'
							res.status 400 .render 'error' { err:'Not Sent Correctly' }
						| 'UNAUTHORIZED'
							res.status 401 .render 'error' { err:'Unauthorized' }
						| _
							res.status 500 .render 'error' { err:'There was an error... Where did it go...?' }
				else
					next!
		]
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
	winston.warn "TESTING MODE THIS MODE IS *NOT* SAFE."
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
