require! {
	"async"
	"bcrypt"
	"mongoose"
	"winston"
}

var school, \
	student, astudent, bstudent, xstudent, ystudent, zstudent, \
	faculty, bfaculty, gfaculty, xfaculty, yfaculty, zfaculty, \
	admin, badmin, xadmin, yadmin, zadmin, \
	course1, course2, course3, course4, \
	hashPassword, semester1, semester2

require("../databases/mongoose")
School = mongoose.models.School
User = mongoose.models.User
Course = mongoose.models.Course
Semester = mongoose.models.Semester

db = mongoose.connection
db.open (process.env.mongo||process.env.MONGO||"mongodb://127.0.0.1/lissome")
db.on "error", winston.error.bind winston, "mongo: connection error"

err <- db.once "open"
winston.error err if err

err <- async.waterfall [
	(done)->
		err, hash <- bcrypt.hash "password", 10
		winston.error err if err
		hashPassword? := hash
		done err
	(done)->
		# school
		err,result <- School.find { "name":(process.env.school||process.env.SCHOOL) }
		if err
			winston.error err
			done err
		else
			if result? and result.length > 0
				school := result.0
				winston.info "School exists"
				done!
			else
				school := new School {
					name: (process.env.school||process.env.SCHOOL)
				}
				err, school <- school.save
				winston.error err if err
				school? := school
				winston.info "School created"
				done err
	(done)->
		# student
		err,result <- User.find { "username":"student", "type":1, "school":(process.env.school||process.env.SCHOOL) }
		if err
			winston.error err
			done err
		else
			if result? and result.length > 0
				student := result.0
				winston.info "Student exists"
				done!
			else
				student := new User {
					id: 11
					username: "student"
					firstName: "Kyler"
					middleName: "I have a middle name"
					lastName: "Jakeman"
					email: "student@kean.edu"
					hash: hashPassword
					school: (process.env.school||process.env.SCHOOL)
					type: 1
				}
				err, student <- student.save
				winston.error err if err
				student? := student
				winston.info "Student created"
				done err
	(done)->
		# astudent
		err,result <- User.find { "username":"astudent", "type":1, "school":(process.env.school||process.env.SCHOOL) }
		if err
			winston.error err
			done err
		else
			if result? and result.length > 0
				astudent := result.0
				winston.info "astudent exists"
				done!
			else
				astudent := new User {
					id: 12
					username: "astudent"
					firstName: "Sly"
					lastName: "Traiylor"
					email: "astudent@kean.edu"
					hash: hashPassword
					school: (process.env.school||process.env.SCHOOL)
					type: 1
				}
				err, astudent <- astudent.save
				winston.error err if err
				astudent? := astudent
				winston.info "aStudent created"
				done err
	(done)->
		# bstudent
		err,result <- User.find { "username":"bstudent", "type":1, "school":(process.env.school||process.env.SCHOOL) }
		if err
			winston.error err
			done err
		else
			if result? and result.length > 0
				bstudent := result.0
				winston.info "bstudent exists"
				done!
			else
				bstudent := new User {
					id: 13
					username: "bstudent"
					firstName: "Carver"
					lastName: "Pearce"
					email: "bstudent@kean.edu"
					hash: hashPassword
					school: (process.env.school||process.env.SCHOOL)
					type: 1
					pin: {
						required: true
						method: "unknown"
					}
				}
				err, bstudent <- bstudent.save
				winston.error err if err
				bstudent? := bstudent
				winston.info "bStudent created"
				done err
	(done)->
		# xstudent
		err,result <- User.find { "username":"xstudent", "type":1, "school":(process.env.school||process.env.SCHOOL) }
		if err
			winston.error err
			done err
		else
			if result? and result.length > 0
				astudent := result.0
				winston.info "xstudent exists"
				done!
			else
				xstudent := new User {
					id: 14
					username: "xstudent"
					firstName: "Clay"
					lastName: "Dennis"
					email: "xstudent@kean.edu"
					hash: hashPassword
					school: (process.env.school||process.env.SCHOOL)
					type: 1
					pin: {
						required: true
						method: "pushbullet"
						token: "burtonmodel@gmail.com"
					}
				}
				err, xstudent <- xstudent.save
				winston.error err if err
				xstudent? := xstudent
				winston.info "xStudent created"
				done err
	(done)->
		# ystudent
		err,result <- User.find { "username":"ystudent", "type":1, "school":(process.env.school||process.env.SCHOOL) }
		if err
			winston.error err
			done err
		else
			if result? and result.length > 0
				astudent := result.0
				winston.info "ystudent exists"
				done!
			else
				ystudent := new User {
					id: 15
					username: "ystudent"
					firstName: "Lochan"
					lastName: "Axel"
					email: "ystudent@kean.edu"
					hash: hashPassword
					school: (process.env.school||process.env.SCHOOL)
					type: 1
					pin: {
						required: true
						method: "pushover"
						token: "uvMDxy1CwWNvVSVDjBzN2L1rC9aMmF"
					}
				}
				err, ystudent <- ystudent.save
				winston.error err if err
				ystudent? := ystudent
				winston.info "yStudent created"
				done err
	(done)->
		# zstudent
		err,result <- User.find { "username":"zstudent", "type":1, "school":(process.env.school||process.env.SCHOOL) }
		if err
			winston.error err
			done err
		else
			if result? and result.length > 0
				admin := result.0
				winston.info "zstudent exists"
				done!
			else
				zstudent := new User {
					id: 16
					username: "zstudent"
					firstName: "Totp"
					lastName: "Usar"
					email: "zstudent@kean.edu"
					hash: hashPassword
					school: (process.env.school||process.env.SCHOOL)
					type: 1
					otp: {
						secret: "4JZPEQXTGFNCR76H"
					}
				}
				err, zstudent <- zstudent.save
				winston.error err if err
				zstudent? := zstudent
				winston.info "zStudent created"
				done err
	(done)->
		# faculty
		err,result <- User.find { "username":"faculty", "type":2, "school":(process.env.school||process.env.SCHOOL) }
		if err
			winston.error err
			done err
		else
			if result? and result.length > 0
				faculty := result.0
				winston.info "faculty exists"
				done!
			else
				faculty := new User {
					id: 21
					username: "faculty"
					firstName: "Ralph"
					lastName: "Frost"
					email: "faculty@kean.edu"
					hash: hashPassword
					school: (process.env.school||process.env.SCHOOL)
					type: 2
				}
				err, faculty <- faculty.save
				winston.error err if err
				faculty? := faculty
				winston.info "Faculty created"
				done err
	(done)->
		# bfaculty
		err,result <- User.find { "username":"bfaculty", "type":2, "school":(process.env.school||process.env.SCHOOL) }
		if err
			winston.error err
			done err
		else
			if result? and result.length > 0
				bfaculty := result.0
				winston.info "bfaculty exists"
				done!
			else
				bfaculty := new User {
					id: 22
					username: "bfaculty"
					firstName: "Carver"
					lastName: "Pearce"
					email: "bfaculty@kean.edu"
					hash: hashPassword
					school: (process.env.school||process.env.SCHOOL)
					type: 2
					pin: {
						required: true
						method: "unknown"
					}
				}
				err, bfaculty <- bfaculty.save
				winston.error err if err
				bfaculty? := bfaculty
				winston.info "bFaculty created"
				done err
	(done)->
		# gfaculty
		err,result <- User.find { "username":"gfaculty", "type":2, "school":(process.env.school||process.env.SCHOOL) }
		if err
			winston.error err
			done err
		else
			if result? and result.length > 0
				gfaculty := result.0
				winston.info "gfaculty exists"
				done!
			else
				gfaculty := new User {
					id: 23
					username: "gfaculty"
					firstName: "Shaw"
					lastName: "Hanson"
					email: "gfaculty@kean.edu"
					hash: hashPassword
					school: (process.env.school||process.env.SCHOOL)
					type: 2
				}
				err, faculty <- gfaculty.save
				winston.error err if err
				gfaculty? := gfaculty
				winston.info "gFaculty created"
				done err
	(done)->
		# xfaculty
		err,result <- User.find { "username":"xfaculty", "type":2, "school":(process.env.school||process.env.SCHOOL) }
		if err
			winston.error err
			done err
		else
			if result? and result.length > 0
				astudent := result.0
				winston.info "xfaculty exists"
				done!
			else
				xfaculty := new User {
					id: 24
					username: "xfaculty"
					firstName: "Clay"
					lastName: "Dennis"
					email: "xfaculty@kean.edu"
					hash: hashPassword
					school: (process.env.school||process.env.SCHOOL)
					type: 2
					pin: {
						required: true
						method: "pushbullet"
						token: "burtonmodel@gmail.com"
					}
				}
				err, xfaculty <- xfaculty.save
				winston.error err if err
				xfaculty? := xfaculty
				winston.info "xFaculty created"
				done err
	(done)->
		# yfaculty
		err,result <- User.find { "username":"yfaculty", "type":2, "school":(process.env.school||process.env.SCHOOL) }
		if err
			winston.error err
			done err
		else
			if result? and result.length > 0
				astudent := result.0
				winston.info "yfaculty exists"
				done!
			else
				yfaculty := new User {
					id: 25
					username: "yfaculty"
					firstName: "Lochan"
					lastName: "Axel"
					email: "yfaculty@kean.edu"
					hash: hashPassword
					school: (process.env.school||process.env.SCHOOL)
					type: 2
					pin: {
						required: true
						method: "pushover"
						token: "uvMDxy1CwWNvVSVDjBzN2L1rC9aMmF"
					}
				}
				err, yfaculty <- yfaculty.save
				winston.error err if err
				yfaculty? := yfaculty
				winston.info "yFaculty created"
				done err
	(done)->
		# zfaculty
		err,result <- User.find { "username":"zfaculty", "type":2, "school":(process.env.school||process.env.SCHOOL) }
		if err
			winston.error err
			done err
		else
			if result? and result.length > 0
				zfaculty := result.0
				winston.info "zfaculty exists"
				done!
			else
				zfaculty := new User {
					id: 26
					username: "zfaculty"
					firstName: "Totp"
					lastName: "Usar"
					email: "zfaculty@kean.edu"
					hash: hashPassword
					school: (process.env.school||process.env.SCHOOL)
					type: 2
					otp: {
						secret: "4JZPEQXTGFNCR76H"
					}
				}
				err, faculty <- zfaculty.save
				winston.error err if err
				gfaculty? := faculty
				winston.info "yFaculty created"
				done err
	(done)->
		# admin
		err,result <- User.find { "username":"admin", "type":3, "school":(process.env.school||process.env.SCHOOL) }
		if err
			winston.error err
			done err
		else
			if result? and result.length > 0
				admin := result.0
				winston.info "admin exists"
				done!
			else
				admin := new User {
					id: 31
					username: "admin"
					firstName: "Carver"
					lastName: "Pearce"
					email: "admin@kean.edu"
					hash: hashPassword
					school: (process.env.school||process.env.SCHOOL)
					type: 3
				}
				err, admin <- admin.save
				winston.error err if err
				admin? := admin
				winston.info "Admin created"
				done err
	(done)->
		# badmin
		err,result <- User.find { "username":"badmin", "type":3, "school":(process.env.school||process.env.SCHOOL) }
		if err
			winston.error err
			done err
		else
			if result? and result.length > 0
				badmin := result.0
				winston.info "badmin exists"
				done!
			else
				badmin := new User {
					id: 32
					username: "badmin"
					firstName: "Carver"
					lastName: "Pearce"
					email: "badmin@kean.edu"
					hash: hashPassword
					school: (process.env.school||process.env.SCHOOL)
					type: 3
					pin: {
						required: true
						method: "unknown"
					}
				}
				err, badmin <- badmin.save
				winston.error err if err
				badmin? := badmin
				winston.info "bAdmin created"
				done err
	(done)->
		# xadmin
		err,result <- User.find { "username":"xadmin", "type":1, "school":(process.env.school||process.env.SCHOOL) }
		if err
			winston.error err
			done err
		else
			if result? and result.length > 0
				astudent := result.0
				winston.info "xadmin exists"
				done!
			else
				xadmin := new User {
					id: 33
					username: "xadmin"
					firstName: "Clay"
					lastName: "Dennis"
					email: "xadmin@kean.edu"
					hash: hashPassword
					school: (process.env.school||process.env.SCHOOL)
					type: 1
					pin: {
						required: true
						method: "pushbullet"
						token: "burtonmodel@gmail.com"
					}
				}
				err, xadmin <- xadmin.save
				winston.error err if err
				xadmin? := xadmin
				winston.info "xAdmin created"
				done err
	(done)->
		# yadmin
		err,result <- User.find { "username":"yadmin", "type":3, "school":(process.env.school||process.env.SCHOOL) }
		if err
			winston.error err
			done err
		else
			if result? and result.length > 0
				astudent := result.0
				winston.info "yadmin exists"
				done!
			else
				yadmin := new User {
					id: 34
					username: "yadmin"
					firstName: "Lochan"
					lastName: "Axel"
					email: "yadmin@kean.edu"
					hash: hashPassword
					school: (process.env.school||process.env.SCHOOL)
					type: 3
					pin: {
						required: true
						method: "pushover"
						token: "uvMDxy1CwWNvVSVDjBzN2L1rC9aMmF"
					}
				}
				err, yadmin <- yadmin.save
				winston.error err if err
				yadmin? := yadmin
				winston.info "yAdmin created"
				done err
	(done)->
		# zadmin
		err,result <- User.find { "username":"zadmin", "type":3, "school":(process.env.school||process.env.SCHOOL) }
		if err
			winston.error err
			done err
		else
			if result? and result.length > 0
				admin := result.0
				winston.info "admin exists"
				done!
			else
				zadmin := new User {
					id: 35
					username: "zadmin"
					firstName: "Totp"
					lastName: "Usar"
					email: "zadmin@kean.edu"
					hash: hashPassword
					school: (process.env.school||process.env.SCHOOL)
					type: 3
					otp: {
						secret: "4JZPEQXTGFNCR76H"
					}
				}
				err, zadmin <- zadmin.save
				winston.error err if err
				zadmin? := zadmin
				winston.info "zAdmin created"
				done err
	(done)->
		# Fall 2015 semester
		err,result <- Semester.find { "title":"Fall 2015", "school":(process.env.school||process.env.SCHOOL) }
		if err
			winston.error err
			done err
		else
			if result? and result.length > 0
				semester1 := result.0
				winston.info "Semester Exists"
				done!
			else
				semester1 := new Semester {
					title: "Fall 2015"
					school: (process.env.school||process.env.SCHOOL)
					open: "Jan 1 2000"
					close: "Jan 1 3000"
				}
				err,semester1 <- semester1.save
				winston.error err if err
				semester1? := semester1
				winston.info "Semester created"
				done err
	(done)->
		# Spring 2016 semester
		err,result <- Semester.find { "title":"Spring 2016", "school":(process.env.school||process.env.SCHOOL) }
		if err
			winston.error err
			done err
		else
			if result? and result.length > 0
				semester2 := result.0
				winston.info "Semester Exists"
				done!
			else
				semester2 := new Semester {
					title: "Spring 2016"
					school: (process.env.school||process.env.SCHOOL)
					open: "Jan 1 2016"
					close: "Jun 1 2016"
				}
				err,semester2 <- semester2.save
				winston.error err if err
				semester2? := semester2
				winston.info "Semester created"
				done err
	(done)->
		# cps1234*02
		err,result <- Course.find { "id":"cps1234", "school":(process.env.school||process.env.SCHOOL) }
		if err
			winston.error err
			done err
		else
			if result? and result.length > 0
				course1 := result.0
				winston.info "Course exists"
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
						xstudent._id
						ystudent._id
					]
					school: (process.env.school||process.env.SCHOOL)
					semester: semester1._id
				}
				err,course1 <- course1.save
				winston.error err if err
				course1 := course1
				winston.info "Course created"
				done err
	(done)->
		# ge1000
		err,result <- Course.find { "id":"ge1000", "semester":semester1._id, "school":(process.env.school||process.env.SCHOOL) }
		if err
			winston.error err
			done err
		else
			if result? and result.length > 0
				course2 := result.0
				winston.info "Course exists"
				done!
			else
				course2 := new Course {
					id: "ge1000"
					title: "Transition to Kean (Fall 2015)"
					faculty: [ # faculty's username(s)
						gfaculty._id
					]
					students: [ # student's username(s)
						student._id
						xstudent._id
					]
					school: (process.env.school||process.env.SCHOOL)
					semester: semester1._id
				}
				err,course2 <- course2.save
				winston.error err if err
				course2 := course2
				winston.info "Course created"
				done err
	(done)->
		# ge1000
		err,result <- Course.find { "id":"ge1000*01", "semester":semester2._id, "school":(process.env.school||process.env.SCHOOL) }
		if err
			winston.error err
			done err
		else
			if result? and result.length > 0
				course4 := result.0
				winston.info "Course exists"
				done!
			else
				course4 := new Course {
					id: "ge1000*01"
					title: "Transition to Kean (Spring 2016)"
					faculty: [ # faculty's username(s)
						gfaculty._id
					]
					students: [ # student's username(s)
						student._id
						ystudent._id
					]
					school: (process.env.school||process.env.SCHOOL)
					semester: semester2._id
				}
				err,course4 <- course4.save
				course4 := course4
				winston.info "Course created"
				done err
	(done)->
		# cps4601
		err,result <- Course.find { "id":"cps4601", "school":(process.env.school||process.env.SCHOOL) }
		if err
			winston.error err
			done err
		else
			if result? and result.length > 0
				course3 := result.0
				winston.info "Course exists"
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
				err,course3 <- course3.save
				course3? := course3
				winston.info "Course created"
				done err
]

winston.error err if err
err <- db.close
winston.error err if err
