require! {
	"async"
	"bcrypt"
	"mongoose"
}
schemas = require("./schemas")(mongoose)
School = mongoose.model "School" schemas.School
User = mongoose.model "User" schemas.User
Semester = mongoose.model "Semester" schemas.Semester
Course = mongoose.model "Course" schemas.Course
Assignment = mongoose.model "Assignment" schemas.Assignment
Attempt = mongoose.model "Attempt" schemas.Attempt
Thread = mongoose.model "Thread" schemas.Thread
Post = mongoose.model "Post" schemas.Post

db = mongoose.connection
mongouser = if process.env.mongouser or process.env.MONGOUSER then ( process.env.mongouser || process.env.MONGOUSER )
mongopass = if process.env.mongopass or process.env.MONGOPASS then ( process.env.mongopass || process.env.MONGOPASS )
db.open (process.env.mongo||process.env.MONGOURL||"mongodb://localhost/smrtboard"), { "user": mongouser, "pass": mongopass }
# db.on "disconnect", -> db.connect!
db.on "error", console.error.bind console, "connection error:"

async.parallel [
	(done)->
		err,result <- School.remove {}
		if err?
			console.error err
			done err
		else
			console.log "deleted #{result} School(s)"
			done!
	(done)->
		err,result <- User.remove {}
		if err?
			console.error err
			done err
		else
			console.log "deleted #{result} User(s)"
			done!
	(done)->
		err,result <- Semester.remove {}
		if err?
			console.error err
			done err
		else
			console.log "deleted #{result} Course(s)"
			done!
	(done)->
		err,result <- Course.remove {}
		if err?
			console.error err
			done err
		else
			console.log "deleted #{result} Course(s)"
			done!
	(done)->
		err,result <- Assignment.remove {}
		if err?
			console.error err
			done err
		else
			console.log "deleted #{result} Assignment(s)"
			done!
	(done)->
		err,result <- Attempt.remove {}
		if err?
			console.error err
			done err
		else
			console.log "deleted #{result} Attempt(s)"
			done!
	(done)->
		err,result <- Thread.remove {}
		if err?
			console.error err
			done err
		else
			console.log "deleted #{result} Post(s)"
			done!
	(done)->
		err,result <- Post.remove {}
		if err?
			console.error err
			done err
		else
			console.log "deleted #{result} Post(s)"
			done!
	(done)->
		db.close!
		done!
]
