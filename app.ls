#!/usr/bin/env lsc
require! {
	express
	swig
	winston
	'serve-static'
	'fs-extra'
	'express-session'
	mongoose
	'./schemas'
}
Schema = mongoose.Schema
fs = fsExtra
app = express!

mongoose.connect (process.env.MONGO || 'mongodb://localhost/smrtboard')

# mongoose schemas
SchoolS = new Schema {name:String,students:[StudentS],teachers:[TeacherS],admins:[AdminS]}
StudentS = new Schema {studentid:Number,classes:[CourseS],first:String,middle:String,last:String,username:String,hash:String}
TeacherS = new Schema {teacherid:Number,classes:[CourseS],first:String,middle:String,last:String,username:String,hash:String}
AdminS = new Schema {adminid:Number,first:String,middle:String,last:String,username:String,hash:String}
ReqS = new Schema {body:String,time:{ type: Date, default: Date.now },author: Schema.Types.Mixed,/*{ type: Student }*/files:Buffer,due:{ type: Date, default: Date.now },tries:{ type: Number, default: 1 },/*attempts:{student:}*/}
PostS = new Schema {body:String,time:{ type: Date, default: Date.now },author: Schema.Types.Mixed,/*{ type: Student }*/files:Buffer}
ThreadS = new Schema {title:String,posts:[PostS]}
CourseS = new Schema {conference:[ThreadS],blog:[PostS],exams:[ReqS],assignments:[ReqS],dm:Schema.Types.Mixed,grades:Schema.Types.Mixed,teachers:[TeacherS],registered:[StudentS]}

SchoolM = mongoose.model 'University', SchoolS
StudentM = mongoose.model 'Student', StudentS
TeacherM = mongoose.model 'Teacher', TeacherS
ReqM = mongoose.model 'Req', ReqS
PostM = mongoose.model 'Post', PostS
ThreadM = mongoose.model 'Thread', ThreadS
CourseM = mongoose.model 'Course', CourseS

# Settings
app
	.disable 'x-powered-by' # best security practice to hide
	# swig template setup
	.engine 'html', swig.renderFile
	.set 'view engine', 'html'
	.set 'views', __dirname + '/views'
	# static assets
	.use '/assets', serveStatic './assets'
	# sessions
	.use expressSession {
		secret: fs.readFileSync('secret.key', \utf-8),
		resave: false,
		saveUninitialized: true,
		cookie: {
			path: \/,
			httpOnly: true
		}
	}

if app.get 'env' is 'production'
	# production run
	app
		.use csrf!
		.use compression
else
	# development/other run
	require! util
	app.set 'view cache', false
	swig.setDefaults { cache: false }

app
	# all routes here are pre-processing/validation
	..route '*'
	.all (req, res, next)->
		if !req.app.locals.isLoggedin(req) # check loggedin
			if req.path is '/login'
				next!
			else
				res.redirect '/login'
		else
			next!
	.all (req, res, next)->
		# parse form data
		if req.method.toLowerCase! in ['post','put','patch','delete']
			winston.info 'handled a form'
			form = new formidable.IncomingForm!
			form.hash = \md5
			form.multiples = true
			form.parse req, (err, fields, files)->
				if err?
					winston.error 'login:formidable '+err
					res.status 500 .send err
				else
					req.fields = fields
					req.files = files
			form.on 'end', ->
				next!
		else
			next!
	..route '/:type(admin|teacher)'
	.all (req, res, next)->
		if !req.app.locals.isTeacher(req) or !req.app.locals.isAdmin(req)
			res.status 403 .send 'Forbidden'
		else
			next!
	..route '/:type(admin|teacher)/*'
	.all (req, res, next)->
		if !req.app.locals.isTeacher(req) or !req.app.locals.isAdmin(req)
			res.status 403 .send 'Forbidden'
		else
			next!
	..use '/', require './base'
	# app functions
	..locals.isLoggedin = (req)->
		# TODO: add session timeout check
		if req.session.username?
			return true
		return false
	..locals.isTeacher = (req)->
		# TODO: add session timeout check
		if req.session.teacher?
			if req.session.teacher is true
				return true
		return false
	..locals.isAdmin = (req)->
		# TODO: add session timeout check
		if req.session.admin?
			if req.session.admin is true
				return true
		return false
	..locals.util = if util? then util
	..locals.winston = winston
	..locals.fs = fsExtra

if process.env.HTTP? or process.env.PORT?
	port = (process.env.HTTP || process.env.PORT)
	winston.info 'started on port '+port+' at '+new Date Date.now!
	server = app.listen port
else
	console.error 'no port/socket specified please use HTTP or PORT environment variable'
	process.exit(1)
