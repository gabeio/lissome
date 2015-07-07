require! {
	"async"
	"bcrypt"
	"mongoose"
}
schemas = require("./schemas")(mongoose)
School = mongoose.model "School" schemas.School
User = mongoose.model "User" schemas.User
Course = mongoose.model "Course" schemas.Course
Semester = mongoose.model "Semester" schemas.Semester

db = mongoose.connection
mongouser = if process.env.mongouser or process.env.MONGOUSER then ( process.env.mongouser || process.env.MONGOUSER )
mongopass = if process.env.mongopass or process.env.MONGOPASS then ( process.env.mongopass || process.env.MONGOPASS )
db.open (process.env.mongo||process.env.MONGOURL||"mongodb://localhost/smrtboard"), { "user": mongouser, "pass": mongopass }
# db.on "disconnect", -> db.connect!
db.on "error", console.error.bind console, "connection error:"

var school, student, astudent, faculty,\
	gfaculty, admin, course1, course2, course3,\
	hashPassword, semester1
async.series [
	(done)->
		err, something <- db.once "open"
		hashPassword := bcrypt.hashSync "password", 10
		done!
	(done)->
		# school
		err,result <- School.find { "name":(process.env.school||process.env.SCHOOL) }
		if err
			console.error err
			done err
		else
			if result? and result.length > 0
				school := result.0
				console.log "School exists"
				done!
			else
				school := new School {
					name: (process.env.school||process.env.SCHOOL)
				}
				err, school <- school.save
				if err
					console.error err
				school := school
				console.log school
				done!
	(done)->
		# student
		err,result <- User.find { "username":"student", "type":1, "school":(process.env.school||process.env.SCHOOL) }
		if err
			console.error err
			done err
		else
			if result? and result.length > 0
				student := result.0
				console.log "Student exists"
				done!
			else
				student := new User {
					id: 1
					username: "student"
					firstName: "Kyler"
					lastName: "Jakeman"
					email: "student@kean.edu"
					hash: hashPassword
					school: (process.env.school||process.env.SCHOOL)
					type: 1
					courses:["cps1234*02", "ge1000*04"]
				}
				err, student <- student.save
				student := student
				if err
					console.error err
				console.log student
				done!
	(done)->
		# astudent
		err,result <- User.find { "username":"astudent", "type":1, "school":(process.env.school||process.env.SCHOOL) }
		if err
			console.error err
			done err
		else
			if result? and result.length > 0
				astudent := result.0
				console.log "astudent exists"
				done!
			else
				astudent := new User {
					id: 2
					username: "astudent"
					firstName: "Sly"
					lastName: "Traiylor"
					email: "astudent@kean.edu"
					hash: hashPassword
					school: (process.env.school||process.env.SCHOOL)
					type: 1
					courses:["cps1234*02", "ge1000*04"]
				}
				err, astudent <- astudent.save
				astudent := astudent
				if err
					console.error err
				console.log astudent
				done!
	(done)->
		# faculty
		err,result <- User.find { "username":"faculty", "type":2, "school":(process.env.school||process.env.SCHOOL) }
		if err
			console.error err
			done err
		else
			if result? and result.length > 0
				faculty := result.0
				console.log "faculty exists"
				done!
			else
				faculty := new User {
					id: 3
					username: "faculty"
					firstName: "Ralph"
					lastName: "Frost"
					email: "faculty@kean.edu"
					hash: hashPassword
					school: (process.env.school||process.env.SCHOOL)
					type: 2
					courses:["cps1234*02"]
				}
				err, faculty <- faculty.save
				faculty := faculty
				if err
					console.error err
				console.log faculty
				done!
	(done)->
		# gfaculty
		err,result <- User.find { "username":"gfaculty", "type":2, "school":(process.env.school||process.env.SCHOOL) }
		if err
			console.error err
			done err
		else
			if result? and result.length > 0
				gfaculty := result.0
				console.log "gfaculty exists"
				done!
			else
				gfaculty := new User {
					id: 4
					username: "gfaculty"
					firstName: "Shaw"
					lastName: "Hanson"
					email: "gfaculty@kean.edu"
					hash: hashPassword
					school: (process.env.school||process.env.SCHOOL)
					type: 2
					courses:["ge1000*04"]
				}
				err, faculty <- gfaculty.save
				gfaculty := faculty
				if err
					console.error err
				console.log faculty
				done!
	(done)->
		# admin
		err,result <- User.find { "username":"admin", "type":3, "school":(process.env.school||process.env.SCHOOL) }
		if err
			console.error err
			done err
		else
			if result? and result.length > 0
				admin := result.0
				console.log "admin exists"
				done!
			else
				admin := new User {
					id: 5
					username: "admin"
					firstName: "Carver"
					lastName: "Pearce"
					email: "admin@kean.edu"
					hash: hashPassword
					school: (process.env.school||process.env.SCHOOL)
					type: 3
				}
				err, admin <- admin.save
				admin := admin
				if err
					console.error err
				console.log admin
				done!
	(done)->
		# Fall 2015 semester
		err,result <- Semester.find { "title":"Fall 2015", "school":(process.env.school||process.env.SCHOOL) }
		if err
			console.error err
			done err
		else
			if result? and result.length > 0
				semester1 := result.0
				console.log "Semester Exists"
				done!
			else
				semester1 := new Semester {
					title: "Fall 2015"
					school: (process.env.school||process.env.SCHOOL)
					open: "Jan 1 2000"
					close: "Jan 1 3000"
				}
				err,semester <- semester1.save
				if err
					console.error
					done err
				else
					semester1 := semester
					console.log semester
					done!
	(done)->
		# cps1234*02
		err,result <- Course.find { "id":"cps1234", "school":(process.env.school||process.env.SCHOOL) }
		if err
			console.error err
			done err
		else
			if result? and result.length > 0
				course1 := result.0
				console.log "Course exists"
				done!
			else
				course1 := new Course {
					id: "cps1234"
					title: "Intro to Java"
					faculty: [ # faculty's username(s)
						faculty._id
					]
					students: [ # student's username(s)
						student._id
					]
					school: (process.env.school||process.env.SCHOOL)
					semester: semester1._id
				}
				err,course <- course1.save
				if err
					console.error err
					done err
				else
					course1 := course
					console.log course
					done!
	(done)->
		# ge1000
		err,result <- Course.find { "id":"ge1000", "school":(process.env.school||process.env.SCHOOL) }
		if err
			console.error err
			done err
		else
			if result? and result.length > 0
				course2 := result.0
				console.log "Course exists"
				done!
			else
				course2 := new Course {
					id: "ge1000"
					title: "Transition to Kean"
					faculty: [ # faculty's username(s)
						gfaculty._id
					]
					students: [ # student's username(s)
						student._id
					]
					school: (process.env.school||process.env.SCHOOL)
					semester: semester1._id
				}
				err,course <- course2.save
				if err
					console.error err
					done err
				else
					course2 := course
					console.log course
					done!
	(done)->
		# cps4601
		err,result <- Course.find { "id":"cps4601", "school":(process.env.school||process.env.SCHOOL) }
		if err
			console.error err
			done err
		else
			if result? and result.length > 0
				course3 := result.0
				console.log "Course exists"
				done!
			else
				course3 := new Course {
					id: "cps4601"
					title: "Human Computer Interaction"
					faculty: [ # faculty's username(s)
						gfaculty._id
					]
					students: [ # student's username(s)
						astudent._id
					]
					school: (process.env.school||process.env.SCHOOL)
					semester: semester1._id
				}
				err,course <- course3.save
				if err
					console.error err
					done err
				else
					course3 := course
					console.log course
					done!
	(done)->
		<- db.close
		done!
]
