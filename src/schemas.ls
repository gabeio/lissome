module.exports = exports = (mongoose)->
	Schema = mongoose.Schema
	# Schools
	School = new Schema {
		name: { # School name, index: true
			type: String
			requred: true
			unique: true
		}
		students: [
			{ type: Number, unique: true }
		] # id list of all student
		teachers: [
			{ type: Number, unique: true }
		] # id list of all teacher
		admins: [
			{ type: Number, unique: true }
		] # id list of all admin
		courses: [ # id list of all courses
			{ type: String, unique: true }
		]
	}
	# School Schemas
	Student = new Schema {
		id: { type: Number, required: true, unique: true }, # Student id
		courses: [
			{ type: String, unique: true }
		] # course id list
		first: String # first name
		middle: String # middle name
		last: String # last name
		username: {
			type: String
			required: true
			unique: true
		}
		hash: { # password bcrypt
			type: String
			+required
		}
		school: { # school name
			type: String
			+required
		}
	}
	Faculty = new Schema {
		id: { type: Number, required: true, unique: true } # Faculty id
		courses: [
			{ type: String, unique: true }
		] # course id
		first: String # first name
		middle: String # middle name
		last: String # last name
		username: {
			type: String
			required: true
			unique: true
		}
		hash: { # password bcrypt
			type: String
			+required
		}
		school: { # school name
			type: String
			+required
		}
	}
	Admin = new Schema {
		id: { type: Number, required: true, unique: true } # Admin id
		first: String # first name
		middle: String # middle name
		last: String # last name
		username: {
			type: String
			required: true
			unique: true
		}
		hash: { # password bcrypt
			type: String
			+required
		}
		school: { # school name
			type: String
			+required
		}
	}
	Course = new Schema {
		subject: { type: String, required: true } # cps
		id: { type: Number, required: true } # 1231
		section: String # *02
		title: { type: String } # Intro to Java
		conference: [] # Thread
		blog: [] # Post
		exams: [] # Req
		assignments: [] # Req
		dm: {} # tid:{sid:[posts]}
		grades: {} # sid:[Grades]
		teachers: [ # teacher id(s)
			{ type: Number, required: true, unique: true }
		]
		students: [ # student ids
			{ type: Number, required: true, unique: true }
		]
		school: { # school name
			type: String
			+required
		}
	}
	# Course Schemas
	Req = new Schema {
		uuid: {
			type: String
			+required
			+unique
		}
		text: String # Require's text
		files: Buffer # Require's file(s)?
		author: { type: Number, required: true } # teacher id
		time: { type: Date, default: Date.now } # created
		start: { type: Date,  default: Date.now } # start due
		end: { type: Date } # late time
		tries: { type: Number, default: 1 } # tries per student
		allowLate: { type: Boolean, default: false } # allow late submissions or not
		attempts: {} # student id : [attempt]
		totalPoints: Number
	}
	Attempt = new Schema {
		uuid: {
			type: String
			+required
			+unique
		}
		text: String # student attempt text
		files: Buffer # student attempt file(s)?
		time: { type: Date, default: Date.now } # submission time
		comments: [] # teacher comments list
	}
	Grade = new Schema {
		uuid: {
			type: String
			+required
			+unique
		}
		type: {
			type: String
		} #, match: /^(exam|assign)$/i },
		points: Number # earned points
		total: Number # total points
		id: Number # exam/assign index
		try: Number # attempt index
	}
	# Blog/Conference Schemas
	Thread = new Schema {
		uuid: {
			type: String
			+required
			+unique
		}
		title: String # Thread name
		posts: [] # Post list
		author: { type: Number, required: true }
	}
	Post = new Schema {
		uuid: {
			type: String
			+required
			+unique
		}
		text: String
		files: Buffer
		author: { type: Number, required: true }
		time: { type: Date, default: Date.now }
	}

	module.exports = {
		School: School
		Student: Student
		Faculty: Faculty
		Admin: Admin
		Course: Course
		Req: Req
		Attempt: Attempt
		Grade: Grade
		Thread: Thread
		Post: Post
	}
