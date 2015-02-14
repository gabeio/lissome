require! {
	'bcrypt'
	'mongoose'
	'uuid'
}
schemas = require('./schemas')(mongoose)
School = mongoose.model 'School' schemas.School
User = mongoose.model 'User' schemas.User
Course = mongoose.model 'Course' schemas.Course


db = mongoose.connection
mongouser = if process.env.mongouser or process.env.MONGOUSER then ( process.env.mongouser || process.env.MONGOUSER )
mongopass = if process.env.mongopass or process.env.MONGOPASS then ( process.env.mongopass || process.env.MONGOPASS )
db.open (process.env.mongo||process.env.MONGOURL||'mongodb://localhost/smrtboard'), { 'user': mongouser, 'pass': mongopass }
db.on 'disconnect', -> db.connect!
db.on 'error', console.error.bind console, 'connection error:'

err, something <- db.once 'open'
hashPassword = bcrypt.hashSync 'password', 10

err,result <- School.find { 'name':process.env.school }
if err
	console.error err
if result? and result.length > 0
	console.log 'School exists'
else
	school = new School {
		name: process.env.school
		users: []
		courses: []
	}
	err, school <- school.save
	if err
		console.error err
	console.log school

err,result <- User.find { 'username':'student', 'type':1, 'school':process.env.school }
if err
	console.error err
if result? and result.length > 0
	console.log 'Student exists'
else
	student = new User {
		id: 1
		username: "student"
		hash: hashPassword
		school: process.env.school
		type:1
		courses:["cps1234*02"]
	}
	err, student <- student.save
	if err
		console.error err
	console.log student

err,result <- User.find { 'username':'faculty', 'type':2, 'school':process.env.school }
if err
	console.error err
if result? and result.length > 0
	console.log 'faculty exists'
else
	faculty = new User {
		id: 2
		username: "faculty"
		hash: hashPassword
		school: process.env.school
		type: 2
		courses:["cps1234*02"]
	}
	err, faculty <- faculty.save
	if err
		console.error err
	console.log faculty

err,result <- User.find { 'username':'admin', 'type':3, 'school':process.env.school }
if err
	console.error err
if result? and result.length > 0
	console.log 'admin exists'
else
	admin = new User {
		id: 3
		username: "admin"
		hash: hashPassword
		school: process.env.school
		type: 3
	}
	err, admin <- admin.save
	if err
		console.error err
	console.log admin

err,result <- Course.find { 'uid':'cps1234*02', 'school':process.env.school }
if err
	console.error err
if result? and result.length > 0
	console.log 'Course exists'
else
	course = new Course {
		uuid: uuid.v4!
		uid: "cps1234*02"
		title: "Intro to Java"
		conference: [] # Thread
		blog: [] # Post
		exams: [] # Req
		assignments: [] # Req
		dm: {} # tid:{sid:[posts]}
		grades: {} # sid:[Grades]
		teachers: [ # teacher's username(s)
			"teacher"
		]
		students: [ # student's username(s)
			"student"
		]
		school: process.env.school
	}
	err,course <- course.save
	if err
		console.error err
	console.log course
