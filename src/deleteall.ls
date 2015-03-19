require! {
	'async'
	'bcrypt'
	'mongoose'
}
schemas = require('./schemas')(mongoose)
School = mongoose.model 'School' schemas.School
User = mongoose.model 'User' schemas.User
Course = mongoose.model 'Course' schemas.Course
Post = mongoose.model 'Post' schemas.Post
Assignment = mongoose.model 'Assignment' schemas.Assignment
Attempt = mongoose.model 'Attempt' schemas.Attempt

db = mongoose.connection
mongouser = if process.env.mongouser or process.env.MONGOUSER then ( process.env.mongouser || process.env.MONGOUSER )
mongopass = if process.env.mongopass or process.env.MONGOPASS then ( process.env.mongopass || process.env.MONGOPASS )
db.open (process.env.mongo||process.env.MONGOURL||'mongodb://localhost/smrtboard'), { 'user': mongouser, 'pass': mongopass }
# db.on 'disconnect', -> db.connect!
db.on 'error', console.error.bind console, 'connection error:'

async.series [
	(done)->
		err,result <- School.remove {}
		if err?
			console.log err
			done err
		else
			console.log "supposedly deleted #{result} School(s)"
			done!
	(done)->
		err,result <- User.remove {}
		if err?
			console.log err
			done err
		else
			console.log "supposedly deleted #{result} User(s)"
			done!
	(done)->
		err,result <- Course.remove {}
		if err?
			console.log err
			done err
		else
			console.log "supposedly deleted #{result} Course(s)"
			done!
	(done)->
		err,result <- Post.remove {}
		if err?
			console.log err
			done err
		else
			console.log "supposedly deleted #{result} Post(s)"
			done!
	(done)->
		err,result <- Assignment.remove {}
		if err?
			console.log err
			done err
		else
			console.log "supposedly deleted #{result} Assignment(s)"
			done!
	(done)->
		err,result <- Attempt.remove {}
		if err?
			console.log err
			done err
		else
			console.log "supposedly deleted #{result} Attempt(s)"
			done!
	(done)->
		db.close!
		done!
]
