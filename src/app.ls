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
	"nunjucks" # templates
	"response-time"
	"serve-static" # nginx static
	"winston"
	"yargs" # --var val
	"./databases/redisClient"
	"./databases/mongoClient"
}
var secret
# verbosity level
/* istanbul ignore next verbosity level only set when necessary */
winston.level? = (yargs.argv.v||yargs.argv.verbose)

# express
app = module.exports = express!

# app locals
app
	..locals.smallpassword = parseInt (process.env.smallpassword||process.env.SMALLPASSWORD||yargs.argv.smallpassword||6), 10
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
	else
		secret := (process.env.cookie||process.env.COOKIE||yargs.argv.cookie)
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
		winston.warn "app: mongo uri env undefined trying localhost anyway"
	if !process.env.redis? and !process.env.REDIS? and !yargs.argv.redis?
		winston.warn "app: redis uri env undefined trying localhost anyway"

# markdown-it options
md = new markdown-it {
	html: false
	xhtml: false
	linkify: true
	typographer: true
}

# create nunjucks filters
nun = new nunjucks.Environment new nunjucks.FileSystemLoader 'views'
nun.express app
nun.addFilter "markdown", (input)->
	md.render input
nun.addFilter "toString", (input)->
	input.toString!
nun.addFilter "fromNow", (input)->
	moment input .fromNow!
/* istanbul ignore next function while unused */
nun.addFilter "format", (input, format)->
	moment input .format format
/* istanbul ignore next function while unused */
nun.addFilter "calendar", (input)->
	moment input .calendar!
nun.addFilter "timezone", (input)->
	moment.tz input, "America/New_York" .clone!.tz app.locals.timezone .toString!

# MONGOOSE
app.locals.mongoose = mongoose
require("./databases/mongoose")

# REDIS
app.locals.redis = redisClient
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
	.use helmet.noCache!
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
		secret: secret
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
			client: redisClient
		}
	}
	# hide what we are made of
	.disable "x-powered-by"
	# set extention of templates to html to render in nunjucks
	# .engine "html" nun.render
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
	# nunjucks.configure {
	# 	noCache: true,
	# 	watch: true
	# }
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
app.use require("./middleware")
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

/* istanbul ignore next only executed if a sig(term/int) is sent */
shutdown = ->
	winston.info "app.ls: Gracefully shutting down."
	server.close!
	mongoose.disconnect!
	redisClient.disconnect!
	process.exit 0
/* istanbul ignore next only executed when sigterm is sent */
process.on "SIGTERM", shutdown
/* istanbul ignore next only executed when sigint is sent */
process.on "SIGINT", shutdown
