require! {
	"bcrypt"
	"mongoose"
}
schemas = require("./schemas")(mongoose)
School = mongoose.model "School" schemas.School
User = mongoose.model "User" schemas.User
Course = mongoose.model "Course" schemas.Course
Post = mongoose.model "Post" schemas.Post

db = mongoose.connection
mongouser = if process.env.mongouser or process.env.MONGOUSER then ( process.env.mongouser || process.env.MONGOUSER )
mongopass = if process.env.mongopass or process.env.MONGOPASS then ( process.env.mongopass || process.env.MONGOPASS )
db.open (process.env.mongo||process.env.MONGOURL||"mongodb://localhost/smrtboard"), { "user": mongouser, "pass": mongopass }
db.on "disconnect", -> db.connect!
db.on "error", console.error.bind console, "connection error:"

err,result <- School.remove { "name": process.env.school }
if err?
	console.log err
else
	console.log result
	console.log "supposedly deleted "+process.env.school

err,result <- User.remove { "school": process.env.school }
if err?
	console.log err
else
	console.log result
	console.log "supposedly deleted all Users from "+process.env.school

err,result <- Course.remove { "school": process.env.school }
if err?
	console.log err
else
	console.log result
	console.log "supposedly deleted all Course from "+process.env.school

err,result <- Post.remove { "school": process.env.school }
if err?
	console.log err
else
	console.log result
	console.log "supposedly deleted all Post from "+process.env.school
