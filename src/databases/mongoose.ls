require! {
	"mongoose"
	"q"
	"winston"
	"yargs"
}
mongoose.Promise = q.Promise
schemas = require("./schemas")(mongoose) # get mongoose schemas
User = mongoose.model "User" schemas.User
Semester = mongoose.model "Semester" schemas.Semester
Course = mongoose.model "Course" schemas.Course
Assignment = mongoose.model "Assignment" schemas.Assignment
Attempt = mongoose.model "Attempt" schemas.Attempt
Thread = mongoose.model "Thread" schemas.Thread
Post = mongoose.model "Post" schemas.Post
School = mongoose.model "School" schemas.School
