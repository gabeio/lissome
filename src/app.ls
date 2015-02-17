#!/usr/bin/env lsc
# ``#!/usr/bin/env node`` # uncomment for lsc to node

# Imports/Variables
require! {
	'async'
	'body-parser'
	'compression' # nginx gzip
	'connect-redis'
	'express' # router
	'express-partial-response'
	'express-session' # session
	'fs-extra' # only if needed
	'markdown'
	'method-override'
	# 'mongoose'
	'multer'
	'serve-static' # nginx static
	'swig' # templates
	'util'
	# 'uuid'
	'winston'
	'yargs' # --var val
}
RedisStore = connect-redis(express-session)
argv = yargs.argv
app = module.exports = express!
fs = fsExtra
markdown = markdown.markdown

# load needed libs into app locals
app
	# variables
	..locals.recaptchaPrivateKey = process.env.RECAPKEY
	..locals.school = process.env.school
	# errors
	# ..locals.err = {
	# 	'NOT FOUND': new Error
	# }

/* istanbul ignore next this is just for assurance the env vars are defined */
do ->
	if !process.env.cookie? and !argv.cookie?
		console.log 'REQUIRES COOKIE SECRET'
		process.exit 1
	if !process.env.school? and !argv.school?
		console.log 'REQUIRES SCHOOL NAME'
		process.exit 1
	if !process.env.mongo? and !process.env.MONGOURL? and !argv.mongo?
		console.log 'mongo env undefined\ntrying localhost anyway...'
	if !process.env.redishost? and !process.env.REDISHOST? and !argv.redishost?
		console.log 'redishost env undefined\ntrying localhost anyway...'
	if !process.env.redisport? and !process.env.REDISPORT? and !argv.redisport?
		console.log 'redishost env undefined\ntrying default anyway...'
	if !process.env.redisauth? and !process.env.REDISAUTH? and !argv.redisauth?
		console.log 'redisauth env undefined\ntrying null anyway...'

# create swig |markdown filter
swig.setFilter 'markdown', markdown.toHTML

# REDIS
rediscli = require('./redisClient')(app,\
	(process.env.redishost||process.env.REDISHOST||argv.redishost||'localhost'),\
	(process.env.redisport||process.env.REDISPORT||argv.redisport||6379),\
	(process.env.redisauth||process.env.REDISAUTH||argv.redisauth||void))

# MONGOOSE
mongo = require('./mongoClient')(app,\
	(process.env.mongo||process.env.MONGOURL||argv.mongo||'mongodb://localhost/smrtboard'),\
	(process.env.mongouser||process.env.MONGOUSER||argv.mongouser||void),\
	(process.env.mongopass||process.env.MONGOPASS||argv.mongopass||void))

# App Settings/Middleware
app
	# needs to come first MIGHT NOT WORK...
	.use method-override 'hmo' # Http-Method-Override
	# sessions
	.use express-session {
		secret: process.env.cookie
		-resave
		+saveUninitialized
		cookie: {
			path: '/'
			+httpOnly
		}
		store: new RedisStore {
			ttl: 604800
			prefix: 'smrtboard'
			client: rediscli
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
	.use bodyParser.text! # idk
	.use bodyParser.raw! # idk
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
				if res.locals.csrfToken? # if csurf enabled
					res.locals.csrfToken = req.csrfToken!
			!->
				if req.session? and req.session.auth?
					res.locals.username =  req.session.username
					res.locals.auth = req.session.auth # save auth level for template
			!->
				next!
		]

# Production Switch
switch process.env.NODE_ENV
| 'production'
	# production run
	winston.info "Production Mode"
| _
	# development/other run
	if !module.parent
		winston.info "Development Mode/Unknown Mode"
	require! {
		'util'
		'response-time'
	}
	# disable template cache
	app.set 'view cache' false
	swig.setDefaults { -cache }
	app.locals.util = if util? then util
	app.use response-time!

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
	/*winston.add winston.transports.Console, {level:'warn'}*/
	require('./test')(app)
