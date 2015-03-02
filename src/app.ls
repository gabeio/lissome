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
	'helmet'
	'markdown-it'
	'method-override'
	'moment'
	'moment-timezone'
	'multer'
	'serve-static' # nginx static
	'swig' # templates
	'util'
	'winston'
	'yargs' # --var val
}
var timezone
RedisStore = connect-redis express-session
argv = yargs.argv
app = module.exports = express!
fs = fsExtra
md = new markdown-it {
	html: false
	xhtml: false
	linkify: true
	typographer: true
}

# load needed libs into app locals
app
	# variables
	..locals.recaptchaPrivateKey = process.env.RECAPKEY
	..locals.school = process.env.school
	..locals.swig = swig
	# errors
	# ..locals.err = {
	# 	'NOT FOUND': new Error
	# }

/* istanbul ignore next this is just for assurance the env vars are defined */
do ->
	if !process.env.cookie? and !argv.cookie?
		console.log "REQUIRES COOKIE SECRET"
		process.exit 1
	if !process.env.school? and !argv.school?
		console.log "REQUIRES SCHOOL NAME"
		process.exit 1
	if !process.env.timezone? and !process.env.TIMEZONE? and !argv.timezone?
		console.log "REQUIRES SCHOOL TIMEZONE"
		process.exit 1
	else
		if moment.tz.zone(process.env.timezone or process.env.TIMEZONE or argv.timezone)
			app.locals.timezone = process.env.timezone or process.env.TIMEZONE or argv.timezone
		else
			console.log "Unknown Timezone; crashing..."
			process.exit 1
	if !process.env.mongo? and !process.env.MONGOURL? and !argv.mongo?
		console.log "mongo env undefined\ntrying localhost anyway..."
	if !process.env.redishost? and !process.env.REDISHOST? and !argv.redishost?
		console.log "redishost env undefined\ntrying localhost anyway..."
	if !process.env.redisport? and !process.env.REDISPORT? and !argv.redisport?
		console.log "redishost env undefined\ntrying default anyway..."
	if !process.env.redisauth? and !process.env.REDISAUTH? and !argv.redisauth?
		console.log "redisauth env undefined\ntrying null anyway..."

# create swig |markdown filter
swig.setFilter 'markdown', (input)->
	md.render input
swig.setFilter 'toString', (input)->
	input.toString!	
swig.setFilter 'fromNow', (input)->
	moment(input).fromNow()
/* istanbul ignore next function while unused */
swig.setFilter 'format', (input, format)->
	moment(input).format(format)
/* istanbul ignore next function while unused */
swig.setFilter 'calendar', (input)->
	moment(input).calendar()
swig.setFilter 'timezone', (input)->
	moment.tz(input, "America/New_York").clone().tz(app.locals.timezone).toString!

# REDIS
/* istanbul ignore next */
rediscli = require('./redisClient')(app,\
	(process.env.redishost||process.env.REDISHOST||argv.redishost||'localhost'),\
	(process.env.redisport||process.env.REDISPORT||argv.redisport||6379),\
	(process.env.redisauth||process.env.REDISAUTH||argv.redisauth||void),\
	(process.env.redisdb||process.env.REDISDB||argv.redisdb||0))

# MONGOOSE
/* istanbul ignore next */
mongo = require('./mongoClient')(app,\
	(process.env.mongo||process.env.MONGOURL||argv.mongo||'mongodb://localhost/smrtboard'),\
	(process.env.mongouser||process.env.MONGOUSER||argv.mongouser||void),\
	(process.env.mongopass||process.env.MONGOPASS||argv.mongopass||void))

# App Settings/Middleware
app
	.use helmet!
	.use helmet.contentSecurityPolicy {
		default-src: ["'self'", "assets.lissome.co", "cdnjs.cloudflare.com"]
		script-src: ["'self'", "assets.lissome.co", "maxcdn.bootstrapcdn.com", "cdnjs.cloudflare.com"]
		style-src: ["'self'", "assets.lissome.co", "cdnjs.cloudflare.com", "fonts.googleapis.com"]
		font-src: ["'self'", "assets.lissome.co", "fonts.googleapis.com", "fonts.gstatic.com"]
	}
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
	# method override needs to come before csurf
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
			prefix: app.locals.school
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
	.use '/static' serveStatic './public/static' # static
	.use '/assets' serveStatic './public/assets'
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
				/* istanbul ignore next if remove after implementing csrf tokens around the entire site */
				if res.locals.csrfToken? and req.method.lowerCase! is 'get' # if csurf enabled
					res.locals.csrfToken = req.csrfToken!
			!->
				if req.session? and req.session.auth?
					res.locals.username =  req.session.username
					res.locals.auth = req.session.auth # save auth level for template
			!->
				next!
		]

# Production Switch
/* istanbul ignore next switch */
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
	# assure one of the settings were given
	if process.env.port? or process.env.PORT? or yargs.argv.http? or yargs.argv.port?
		port = process.env.port or process.env.PORT or yargs.argv.http or yargs.argv.port
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
