require!{
	'async'
	'mongoose'
}
schemas = require('./schemas')(mongoose)
School = mongoose.model 'School' schemas.School
User = mongoose.model 'User' schemas.User
Course = mongoose.model 'Course' schemas.Course

db = mongoose.connection
mongouser = if process.env.mongouser or process.env.MONGOUSER then ( process.env.mongouser || process.env.MONGOUSER )
mongopass = if process.env.mongopass or process.env.MONGOPASS then ( process.env.mongopass || process.env.MONGOPASS )
db.open (process.env.mongo||process.env.MONGOURL||'mongodb://localhost/smrtboard'), { 'user': mongouser, 'pass': mongopass }
# db.on 'disconnect', -> db.connect!
db.on 'error', console.error.bind console, 'connection error:'

var school, student, astudent, faculty,\
	gfaculty, admin, course1, course2, course3,\
	hashPassword
async.series [
	(done)->
		err, something <- db.once 'open'
		done!
	(done)->
		err, results <- Course.find!.populate('students').exec
		if err
			winston.error 'Course populate:students', err
		else
			console.log err
			console.log results
			done!
	(done)->
		err, result <- Course.findOne {
			'id': 'cps1234'
			'school': 'Kean University'
		} .populate('students').exec
		console.log 'result',result
		console.log 'result.students',result.students
		for student in result.students
			console.log 'student',student.firstName
		done!
]
