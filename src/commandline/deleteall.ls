require! {
	"async"
	"mongoose"
	"winston"
}

schemas = require("../databases/schemas")(mongoose)
School = mongoose.model "School" schemas.School
User = mongoose.model "User" schemas.User
Semester = mongoose.model "Semester" schemas.Semester
Course = mongoose.model "Course" schemas.Course
Assignment = mongoose.model "Assignment" schemas.Assignment
Attempt = mongoose.model "Attempt" schemas.Attempt
Thread = mongoose.model "Thread" schemas.Thread
Post = mongoose.model "Post" schemas.Post

db = mongoose.connection
db.open (process.env.mongo||process.env.MONGO||"mongodb://127.0.0.1/lissome")
db.on "error", winston.error.bind winston, "connection error"

err <- db.once "open"
winston.error if err

err <- async.parallel [
	(done)->
		err,result <- School.remove {}
		winston.info "deleted #{result} School(s)" if result?
		done err
	(done)->
		err,result <- User.remove {}
		winston.info "deleted #{result} User(s)" if result?
		done err
	(done)->
		err,result <- Semester.remove {}
		winston.info "deleted #{result} Course(s)" if result?
		done err
	(done)->
		err,result <- Course.remove {}
		winston.info "deleted #{result} Course(s)" if result?
		done err
	(done)->
		err,result <- Assignment.remove {}
		winston.info "deleted #{result} Assignment(s)" if result?
		done err
	(done)->
		err,result <- Attempt.remove {}
		winston.info "deleted #{result} Attempt(s)" if result?
		done err
	(done)->
		err,result <- Thread.remove {}
		winston.info "deleted #{result} Post(s)" if result?
		done err
	(done)->
		err,result <- Post.remove {}
		winston.info "deleted #{result} Post(s)" if result?
		done err
]

winston.error err if err
err <- db.close
winston.error err if err
