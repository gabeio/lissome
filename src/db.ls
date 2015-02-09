require! {
	'bcrypt'
	'mongoose'
}
schemas = require('./schemas')(mongoose)
Student = mongoose.model 'Student' schemas.Student
Faculty = mongoose.model 'Faculty' schemas.Faculty
Admin = mongoose.model 'Admin' schemas.Admin

db = mongoose.connection
mongouser = if process.env.mongouser or process.env.MONGOUSER then ( process.env.mongouser || process.env.MONGOUSER )
mongopass = if process.env.mongopass or process.env.MONGOPASS then ( process.env.mongopass || process.env.MONGOPASS )
db.open (process.env.mongo||process.env.MONGOURL||'mongodb://localhost/smrtboard'), { 'user': mongouser, 'pass': mongopass }
db.on 'disconnect', -> db.connect!
db.on 'error', console.error.bind console, 'connection error:'

err, something <- db.once 'open'
hashPassword = bcrypt.hashSync 'password', 10

err,result <- Student.find { 'username':'Student', 'school':process.env.school }
if !result[0]?
	student = new Student {
		id: 1
		username: "Student"
		hash: hashPassword
		school: process.env.school
	}
	err, student <- student.save
	if err
		console.error err
	console.log student
else
	console.log 'student exists'

err,result <- Faculty.find { 'username':'Faculty', 'school':process.env.school }
if !result[0]?
	faculty = new Faculty {
		id: 1
		username: "Faculty"
		hash: hashPassword
		school: process.env.school
	}
	err, faculty <- faculty.save
	if err
		console.error err
	console.log faculty
else
	console.log 'faculty exists'

err,result <- Admin.find { 'username':'Admin', 'school':process.env.school }
if !result[0]?
	admin = new Admin {
		id: 1
		username: "Admin"
		hash: hashPassword
		school: process.env.school
	}
	err, admin <- admin.save
	if err
		console.error err
	console.log admin
else
	console.log 'admin exists'
