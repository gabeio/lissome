# Imports/Variables
require! {
	"async"
	"body-parser"
	"compression" # nginx gzip
	"connect-redis"
	"cors"
	"csurf"
	"express" # router
	"express-partial-response"
	"express-session" # session
	"helmet"
	"markdown-it"
	"method-override"
	"moment"
	"moment-timezone"
	"mongoose"
	"multer"
	"response-time"
	"serve-static" # nginx static
	"swig" # templates
	"winston"
	"yargs" # --var val
}

# verbosity level
winston.level? = (yargs.argv.v||yargs.argv.verbose)

# express
app = module.exports = express!

# app locals
app
	..locals.smallpassword = parseInt (process.env.small||process.env.smallpassword||process.env.minpassword||6)
	..locals.multer = multer { # requires: enctype="multipart/form-data"
		dest: "uploads/"
		limits:
			files: 0 # currently disallow file uploads
			# fileSize: 100mb # currently set to the max cloudflare free allows
		+includeEmptyFields
		-inMemory
	}
	..locals.pushover = {
		token: (process.env.pushover||process.env.PUSHOVER||yargs.argv.pushover)
	}
	..locals.pushbullet = {
		token: (process.env.pushbullet||process.env.PUSHBULLET||yargs.argv.pushbullet)
	}

/* istanbul ignore next this is just for assurance the env vars are defined */
do ->
	if !process.env.cookie? and !process.env.COOKIE? and !yargs.argv.cookie?
		winston.error "app: REQUIRES COOKIE SECRET"
		process.exit 1
	if !process.env.school? and !process.env.SCHOOL? and !yargs.argv.school?
		winston.error "app: REQUIRES SCHOOL NAME"
		process.exit 1
	else
		app.locals.school = (process.env.school||process.env.SCHOOL||yargs.argv.school)
	if !process.env.timezone? and !process.env.TIMEZONE? and !yargs.argv.timezone?
		winston.error "app: REQUIRES SCHOOL TIMEZONE"
		process.exit 1
	else
		if moment.tz.zone(process.env.timezone or process.env.TIMEZONE or yargs.argv.timezone)
			app.locals.timezone = process.env.timezone or process.env.TIMEZONE or yargs.argv.timezone
		else
			winston.error "app: Unknown Timezone; crashing..."
			process.exit 1
	if !process.env.mongo? and !process.env.MONGO? and !yargs.argv.mongo?
		winston.warn "app: mongo env undefined trying localhost anyway"
	if !process.env.redishost? and !process.env.REDISHOST? and !yargs.argv.redishost?
		winston.warn "app: redishost env undefined trying localhost anyway"
	if !process.env.redisport? and !process.env.REDISPORT? and !yargs.argv.redisport?
		winston.warn "app: redisport env undefined trying default anyway"
	if !process.env.redisauth? and !process.env.REDISAUTH? and !yargs.argv.redisauth?
		winston.warn "app: redisauth env undefined trying null anyway"

# markdown-it options
md = new markdown-it {
	html: false
	xhtml: false
	linkify: true
	typographer: true
}

# create swig |markdown filter
swig.setFilter "markdown", (input)->
	md.render input
swig.setFilter "toString", (input)->
	input.toString!
swig.setFilter "fromNow", (input)->
	moment input .fromNow!
/* istanbul ignore next function while unused */
swig.setFilter "format", (input, format)->
	moment input .format format
/* istanbul ignore next function while unused */
swig.setFilter "calendar", (input)->
	moment input .calendar!
swig.setFilter "timezone", (input)->
	moment.tz input, "America/New_York" .clone!.tz app.locals.timezone .toString!

# MONGOOSE
/* istanbul ignore next */
mongo = require("./databases/mongoClient")(app,mongoose,\
	(process.env.mongo||process.env.MONGO||yargs.argv.mongo||"mongodb://localhost/lissome"))

# REDIS
/* istanbul ignore next */
redis = require("./databases/redisClient")(app,\
	(process.env.redis||process.env.REDIS||yargs.argv.redis||"redis://localhost:6379/0"))

app.locals.redis = redis

RedisStore = connect-redis express-session

# App Settings/Middleware
app
	.use response-time!
	.use helmet!
	.use helmet.contentSecurityPolicy {
		default-src: ["'self'",
			"assets.lissome.co",
			"maxcdn.bootstrapcdn.com",
			"cdnjs.cloudflare.com"
		]
		script-src:  ["'self'",
			"assets.lissome.co",
			"maxcdn.bootstrapcdn.com",
			"cdnjs.cloudflare.com"
		]
		style-src:   ["'self'",
			"assets.lissome.co",
			"maxcdn.bootstrapcdn.com",
			"cdnjs.cloudflare.com",
			"fonts.googleapis.com"
		]
		font-src:    ["'self'",
			"assets.lissome.co",
			"maxcdn.bootstrapcdn.com",
			"cdnjs.cloudflare.com",
			"fonts.googleapis.com",
			"fonts.gstatic.com"
		]
	}
	.use helmet.frameguard "deny"
	# body parser
	.use bodyParser.urlencoded {
		+extended
	}
	.use bodyParser.json!
	.use bodyParser.text! # idk
	.use bodyParser.raw! # idk
	# method override needs to come before csurf
	.use method-override "hmo" # Http-Method-Override
	# sessions
	.use express-session {
		secret: (process.env.cookie||process.env.COOKIE||yargs.argv.cookie)
		-resave
		+rolling
		+saveUninitialized
		name: "lissome"
		cookie: {
			path: "/"
			+httpOnly
		}
		store: new RedisStore {
			ttl: 604800
			prefix: app.locals.school
			client: redis
		}
	}
	# hide what we are made of
	.disable "x-powered-by"
	# set extention of templates to html to render in swig
	.engine "html" swig.renderFile
	# set extention of templates to html
	.set "view engine" "html"
	# .set "views" __dirname + "/NOTviews" # /views by default
	# static assets (html,js,css)
	.use "/static" serveStatic "./public/static" # error pages
	.use "/assets" serveStatic "./public/assets" # js, css
	# Cross Origin Resourse Sharing
	.use cors!
	# compress large files
	.use compression!
	# CUSTOM MIDDLEWARE
	.use (req, res, next)->
		err <- async.parallel [
			(para)->
				if req.session? and req.session.uid?
					res.locals.uid = req.session.uid.toString!
					res.locals.firstName = req.session.firstName
					res.locals.lastName = req.session.lastName
					res.locals.username = req.session.username
					res.locals.middleName? = req.session.middleName
					para!
				else
					para!
			(para)->
				if req.session? and req.session.auth?
					res.locals.auth = req.session.auth
					para!
				else
					para!
			(para)->
				/* istanbul ignore if which only tests if redis is offline */
				if !req.session?
					next new Error "Sessions are offline."
				else
					para!
		]
		next err

# Production Switch
/* istanbul ignore next switch */
switch app.get "env"
| "production"
	# production run
	winston.info "app: Production Mode"
	app.use csurf {
		secretLength: 64
		saltLength: 20
	}
| _
	# development/other run
	if !module.parent
		winston.info "app: Development Mode"
	# disable template cache
	app.set "view cache" false
	swig.setDefaults { -cache }
	app.use (req, res, next)->
		req.csrfToken = ->
			return ""
		next!

app
	..locals.authorize = (req, res, next)->
		if res.locals.auth? and res.locals.needs? and res.locals.needs <= res.locals.auth
			next!
		else
			next new Error "UNAUTHORIZED" # other unauth

# Routers
require("./databases/mongoose")(app)
app.use "/login", require("./login")
app.use "/logout", require("./logout")
app.use "/otp", require("./otp")
app.use "/pin", require("./pin")
app.use "/bounce", require("./bounce")
app.use "/preferences", require("./preferences")
app.use "/admin", require("./admin")
app.use "/:course(c|C|course)", require("./course")
app.use "/:index(index|dash|dashboard)?", require("./dashboard")
require("./error")(app)

/* istanbul ignore next */
if !module.parent # assure this file is not being run by a different file
	# assure one of the settings were given
	if process.env.port? or process.env.PORT? or yargs.argv.http? or yargs.argv.port?
		port = process.env.port or process.env.PORT or yargs.argv.http or yargs.argv.port
		winston.info "app: Server started on port " + port + " at " + new Date Date.now!
		server = app.listen port
	else
		winston.error "app: No port/socket specified please use HTTP or PORT environment variable"
		process.exit 1
else
	app.locals.testing = true
	# silence all logging on testing
	winston.level = "error"
	require("./test")(app)
/* istanbul ignore next this is only executed when sigterm is sent */
process.on "SIGTERM", ->
	winston.info "app: Shutting down from SIGTERM"
	server.close!
	mongoose.disconnect!
	redis.end!
	process.exit 0
/* istanbul ignore next this is only executed when sigint is sent */
process.on "SIGINT", ->
	winston.info "app: Gracefully shutting down from SIGINT (Ctrl-C)"
	server.close!
	mongoose.disconnect!
	redis.end!
	process.exit 0
