require! {
	"async"
	"bcrypt"
	"mongoose"
}
schemas = require("./schemas")(mongoose)
School = mongoose.model "School" schemas.School
User = mongoose.model "User" schemas.User
Course = mongoose.model "Course" schemas.Course


db = mongoose.connection
mongouser = if process.env.mongouser or process.env.MONGOUSER then ( process.env.mongouser || process.env.MONGOUSER )
mongopass = if process.env.mongopass or process.env.MONGOPASS then ( process.env.mongopass || process.env.MONGOPASS )
db.open (process.env.mongo||process.env.MONGOURL||"mongodb://localhost/smrtboard"), { "user": mongouser, "pass": mongopass }
# db.on "disconnect", -> db.connect!
db.on "error", console.error.bind console, "connection error:"

var school, student, astudent, faculty,\
	gfaculty, admin, course1, course2, course3,\
	hashPassword
async.series [
	(done)->
		err, something <- db.once "open"
		hashPassword := bcrypt.hashSync "password", 10
		done!
	(done)->
		# school
		err,result <- School.find { "name":process.env.school }
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
					name: process.env.school
				}
				err, school <- school.save
				if err
					console.error err
				school := school
				console.log school
				done!
	(done)->
		# student
		err,result <- User.find { "username":"student", "type":1, "school":process.env.school }
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
					firstName: "Alpha"
					lastName: "Beta"
					email: "student@kean.edu"
					hash: hashPassword
					school: process.env.school
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
		err,result <- User.find { "username":"astudent", "type":1, "school":process.env.school }
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
					firstName: "Alpha1"
					lastName: "Beta1"
					email: "astudent@kean.edu"
					hash: hashPassword
					school: process.env.school
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
		err,result <- User.find { "username":"faculty", "type":2, "school":process.env.school }
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
					firstName: "Alpha2"
					lastName: "Beta2"
					email: "faculty@kean.edu"
					hash: hashPassword
					school: process.env.school
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
		err,result <- User.find { "username":"gfaculty", "type":2, "school":process.env.school }
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
					firstName: "Alpha3"
					lastName: "Beta3"
					email: "gfaculty@kean.edu"
					hash: hashPassword
					school: process.env.school
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
		err,result <- User.find { "username":"admin", "type":3, "school":process.env.school }
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
					firstName: "Alpha4"
					lastName: "Beta4"
					email: "admin@kean.edu"
					hash: hashPassword
					school: process.env.school
					type: 3
				}
				err, admin <- admin.save
				admin := admin
				if err
					console.error err
				console.log admin
				done!
	(done)->
		# cps1234*02
		err,result <- Course.find { "id":"cps1234", "school":process.env.school }
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
					# conference: [] # Thread
					# blog: [] # Post
					# exams: [] # Req
					# assignments: [] # Req
					# dm: {} # tid:{sid:[posts]}
					# grades: {} # sid:[Grades]
					faculty: [ # faculty's username(s)
						faculty._id
					]
					students: [ # student's username(s)
						student._id
					]
					school: process.env.school
				}
				err,course <- course1.save
				course1 := course
				if err
					console.error err
				console.log course
				done!
	(done)->
		# ge1000
		err,result <- Course.find { "id":"ge1000", "school":process.env.school }
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
					# conference: [] # Thread
					# blog: [] # Post
					# exams: [] # Req
					# assignments: [] # Req
					# dm: {} # tid:{sid:[posts]}
					# grades: {} # sid:[Grades]
					faculty: [ # faculty's username(s)
						gfaculty._id
					]
					students: [ # student's username(s)
						student._id
					]
					school: process.env.school
				}
				err,course <- course2.save
				course2 := course
				if err
					console.error err
				console.log course
				done!
	(done)->
		# cps4601
		err,result <- Course.find { "id":"cps4601", "school":process.env.school }
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
					# conference: [] # Thread
					# blog: [] # Post
					# exams: [] # Req
					# assignments: [] # Req
					# dm: {} # tid:{sid:[posts]}
					# grades: {} # sid:[Grades]
					faculty: [ # faculty's username(s)
						gfaculty._id
					]
					students: [ # student's username(s)
						astudent._id
					]
					school: process.env.school
				}
				err,course <- course3.save
				course3 := course
				if err
					console.error err
				console.log course
				done!
	(done)->
		db.close!
		done!
]
