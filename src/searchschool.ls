require! {
	'bcrypt'
	'mongoose'
	'uuid'
}
schemas = require('./schemas')(mongoose)
School = mongoose.model 'School' schemas.School
User = mongoose.model 'User' schemas.User
Course = mongoose.model 'Course' schemas.Course

console.log 'Searching under ',process.env.school

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
	console.log 'No School Found'

err,result <- User.find { 'type':1 'school':process.env.school }
if err
	console.error err
if result? and result.length > 0
	console.log 'Students:', result
else
	console.log 'No Students Found'

err,result <- User.find { 'type':2, 'school':process.env.school }
if err
	console.error err
if result? and result.length > 0
	console.log 'Faculty:',result
else
	console.log 'No Faculty Found'

err,result <- User.find { 'type':3, 'school':process.env.school }
if err
	console.error err
if result? and result.length > 0
	console.log 'Admin:',result
else
	console.log 'No Admins Found'

err,result <- Course.find { 'school':process.env.school }
if err
	console.error err
if result? and result.length > 0
	console.log 'Course:',result
else
	console.log 'No Courses Found'