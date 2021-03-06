module.exports = (mongoose)->
	Schema = mongoose.Schema
	# Schools
	School = new Schema {
		# AUTOCREATED
		# _id
		# REQUIRED
		name: { type: String, +requred, +unique }
	}
	# School Schemas
	User = new Schema {
		# AUTOCREATED
		# _id
		# REQUIRED
		username: { type: String, +required, +unique, +trim }
		hash: { type: String, +required }
		school: { type: String, +required, ref: "School" }
		type: { type: Number, +required, default: 1 }
		firstName: { type: String } # first name
		lastName: { type: String } # last name
		creator: { type: Schema.Types.ObjectId, ref: "User" } # if admins wish to save creator
		email: { type: String, +unique, +required }
		# OPTIONAL
		id: { type: Number, +unique } # school issued id
		middleName: { type: String } # middle name
		otp: {
			secret: { type: String, default: "" } # (t/h)otp secret
		}
		pin: {
			method: { type: String, default: "" } # method of recieving pin
			required: { type:Boolean, default: false } # pin required?
			token: { type: String, default: "" } # user's push token
		}
	}
	User.index { username: 1 }
	Semester = new Schema {
		# AUTOCREATED
		# _id
		author: { type: Schema.Types.ObjectId, ref: "User"}
		timestamp: { type: Date, default: Date.now }
		# REQUIRED
		title: { type: String, +unique, +trim } # ie: Spring of 2015
		school: { type: String, +required, ref: "School" }
		open: { type: Date, +required } # default open time of all courses within
		close: { type: Date, +required } # default close time of all courses within
	}
	Semester.index { title: 1, open: -1 }
	Course = new Schema {
		# AUTOCREATED
		# _id
		author: { type: Schema.Types.ObjectId, ref: "User" }
		timestamp: { type: Date, default: Date.now }
		# REQUIRED
		id: { type: String, +required, +unique } # cps1231*02 # unique identifier given by school
		title: { type: String, +required } # Intro to Java
		school: { type: String, +required, ref: "School" }
		# OPTIONAL
		faculty: [ # faculty usernames
			{ type: Schema.Types.ObjectId, ref: "User" }
		]
		students: [ # student usernames
			{ type: Schema.Types.ObjectId, ref: "User" }
		]
		semester: { type: Schema.Types.ObjectId, ref: "Semester" } # which semester is this course within
		settings: {
			assignments:{
				tries: { type: Number, default: 1 }
				allowLate: { type: Boolean, default: false }
				totalPoints: { type: Number }
				anonymousGrading: { type: Boolean }
			}
		}
		# open: { type: Date }
		# close: { type: Date }
	}
	Course.index { timestamp: -1, id: 1 }
	# Course internal Schemas
	Assignment = new Schema {
		# AUTOCREATED
		author: { type: Schema.Types.ObjectId, +required, ref: "User" }
		timestamp: { type: Date, default: Date.now } # created
		# REQUIRED
		course: { type: Schema.Types.ObjectId, +required, ref: "Course" }
		title: { type: String, +required }
		start: { type: Date,  default: Date.now } # when Date.now > start students can attempt
		tries: { type: Number, default: 1 } # tries per student
		allowLate: { type: Boolean, default: false } # allow late submissions or not
		# OPTIONAL
		end: { type: Date } # when Date.now > end students can't attempt anylonger
		totalPoints: { type: Number }
		text: String # Require's text
		files: Buffer # Require's file(s)?
	}
	Assignment.index { timestamp: -1, course: 1 }
	Attempt = new Schema {
		# AUTOCREATED
		author: { type: Schema.Types.ObjectId, +required, ref: "User" } # student who submitted it
		timestamp: { type: Date, default: Date.now } # submission time
		# REQUIRED
		attempt: Number
		assignment: { type: Schema.Types.ObjectId, +required, ref: "Assignment" }
		course: { type: Schema.Types.ObjectId, +required, ref: "Course" }
		text: String # student attempt text
		files: Buffer # student attempt file(s)?
		points: Number
		letterGrade: String
		grader: { type: Schema.Types.ObjectId, ref: "User" } # teacher who submitted graded it
		late: { type: Boolean, default: false }
	}
	Attempt.index { timestamp: -1, assignment: 1 }
	# Blog/Conference Schemas
	Thread = new Schema {
		# AUTOCREATED
		# _id
		author: { type: Schema.Types.ObjectId, +required, ref: "User" }
		timestamp: { type: Date, default: Date.now }
		course: { type: Schema.Types.ObjectId, +required, ref: "Course" }
		# REQUIRED
		title: String # Thread name
		deleted: Boolean
		# thread: String # Parent Thread
	}
	Thread.index { timestamp: -1, course: 1 }
	Post = new Schema {
		# AUTOCREATED
		# _id
		author: { type: Schema.Types.ObjectId, +required, ref: "User" }
		timestamp: { type: Date, default: Date.now }
		# REQUIRED
		course: { type: Schema.Types.ObjectId, +required, ref: "Course" }
		text: { type: String, +required }
		type: { type: String, +required } # blog/conference
		# OPTIONAL
		thread: { type: Schema.Types.ObjectId, ref: "Thread" } # required if type conference
		title: String
		files: Buffer
		tags: []
		deleted: Boolean
	}
	Post.index { timestamp: -1, course: 1, type: 1 }
	module.exports = {
		School: School
		User: User
		Course: Course
		Semester: Semester
		Assignment: Assignment
		Attempt: Attempt
		Thread: Thread
		Post: Post
	}
