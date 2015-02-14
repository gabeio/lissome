module.exports = (mongoose)->
	Schema = mongoose.Schema
	# Schools
	School = new Schema {
		name: { # School name, index: true
			type: String
			+requred
			+unique
		}
		users: [
			{ type: String, +unique }
		]
		students: [
			{ type: Number, +unique }
		] # id list of all student
		teachers: [
			{ type: Number, +unique }
		] # id list of all teacher
		admins: [
			{ type: Number, +unique }
		] # id list of all admin
		courses: [ # id list of all courses
			{ type: String, +unique }
		]
	}
	# School Schemas
	User = new Schema {
		id: { type: Number, +required, +unique }, # Student id
		first: String # first name
		middle: String # middle name
		last: String # last name
		courses: [
			{ type: String, +unique }# course id list
		]
		username: {
			type: String
			+required
			+trim
		}
		hash: { # password bcrypt
			type: String
			+required
		}
		school: { # school name
			type: String
			+required
		}
		type: { # 1 student 2 faculty 3 admin
			type: Number
			+require
			default: 1
		}
	}
	# Course internal Schemas
	Req = new Schema {
		uuid: {
			type: String
			+required
			+unique
		}
		text: String # Require's text
		files: Buffer # Require's file(s)?
		author: { type: String, +required } # teacher id
		created: { type: Date, default: Date.now } # created
		start: { type: Date,  default: Date.now } # when Date.now > start students can attempt
		end: { type: Date } # when Date.now > end students can't attempt anylonger
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
		time: { type: Date, default: Date.now } # time
	}
	# Blog/Conference Schemas
	Thread = new Schema {
		uuid: {
			type: String
			+required
			+unique
		}
		title: String # Thread name
		posts: [] # Post UUIDs
		author: { type: String, +required }
	}
	Post = new Schema {
		uuid: {
			type: String
			+required
			+unique
		}
		title: String
		text: String
		files: Buffer
		author: { type: String, +required }
		time: { type: Date, default: Date.now }
		tags: []
		type: String # blog/conference/etc
		course: String # course uuid for faster lookups
	}
	Course = new Schema {
		uuid: {
			type: String
			+required
			+unique
		}
		# subject: { type: String, +required } # cps
		uid: { type: String, +required, +unique } # cps1231*02 # unique identifier given by school
		title: { type: String } # Intro to Java
		# conference: [] # Thread UUIDs
		# blog: [] # Post UUIDs
		# exams: [] # Req UUIDs
		# assignments: [] # Req UUIDs
		# dm: {} # tid:{sid:[posts]}
		# grades: {} # sid:[Grades]
		teachers: [ # teacher usernames
			{ type: String, +required, +unique }
		]
		students: [ # student usernames
			{ type: String, +required, +unique }
		]
		school: { # school name
			type: String
			+required
		}
		status: Boolean # open:true closed:false
	}
	module.exports = {
		School: School
		User: User
		Course: Course
		Req: Req
		Attempt: Attempt
		Grade: Grade
		Thread: Thread
		Post: Post
	}
