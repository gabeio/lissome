require! {
	'bcrypt'
	'mongoose'
}
schemas = require('./schemas')(mongoose)
School = mongoose.model 'School' schemas.School
User = mongoose.model 'User' schemas.User
# Student = mongoose.model 'Student' schemas.Student
# Faculty = mongoose.model 'Faculty' schemas.Faculty
# Admin = mongoose.model 'Admin' schemas.Admin
Course = mongoose.model 'Course' schemas.Course
Post = mongoose.model 'Post' schemas.Post

db = mongoose.connection
mongouser = if process.env.mongouser or process.env.MONGOUSER then ( process.env.mongouser || process.env.MONGOUSER )
mongopass = if process.env.mongopass or process.env.MONGOPASS then ( process.env.mongopass || process.env.MONGOPASS )
db.open (process.env.mongo||process.env.MONGOURL||'mongodb://localhost/smrtboard'), { 'user': mongouser, 'pass': mongopass }
db.on 'disconnect', -> db.connect!
db.on 'error', console.error.bind console, 'connection error:'

err, something <- db.once 'open'
hashPassword = bcrypt.hashSync 'password', 10

err,result <- School.remove
if err?
	console.log err
console.log result
console.log 'supposedly deleted *ALL* Schools'

err,result <- User.remove
if err?
	console.log err
console.log result
console.log 'supposedly deleted *ALL* Users'

# err,result <- Student.remove
# if err?
# 	console.log err
# console.log result
# console.log 'supposedly deleted *ALL* Students'

# err,result <- Faculty.remove
# if err?
# 	console.log err
# console.log result
# console.log 'supposedly deleted *ALL* Faculty'

# err,result <- Admin.remove
# if err?
# 	console.log err
# console.log result
# console.log 'supposedly deleted *ALL* Admin'

err,result <- Course.remove
if err?
	console.log err
console.log result
console.log 'supposedly deleted *ALL* Course'

err,result <- Post.remove
if err?
	console.log err
console.log result
console.log 'supposedly deleted *ALL* Post'
