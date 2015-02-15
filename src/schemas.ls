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
		username: { type: String, +required, +trim }
		hash: { type: String, +required }
		school: { type: String, +required }
		type: { type: Number, +require, default: 1 }
		firstName: String # first name
		lastName: String # last name
		# OPTIONAL
		courses: [
			{ type: String, +unique } # course uid list
		]
		id: { type: Number, +required, +unique }, # school issued id
		middleName: String # middle name
	}
	Course = new Schema {
		# AUTOCREATED
		# _id
		author: { type: String, +required }
		timestamp: { type: Date, default: Date.now }
		# REQUIRED
		uid: { type: String, +required, +unique } # cps1231*02 # unique identifier given by school
		title: { type: String } # Intro to Java
		school: { type: String, +required }
		# OPTIONAL
		faculty: [ # faculty usernames
			{ type: String, +required, +unique }
		]
		students: [ # student usernames
			{ type: String, +required, +unique }
		]
		# status: Boolean # open:true closed:false
		open: { type: Date }
		close: { type: Date }
	}
	# Course internal Schemas
	Assignment = new Schema {
		# AUTOCREATED
		author: { type: String, +required } # user id
		timestamp: { type: Date, default: Date.now } # created
		# REQUIRED
		course: String
		title: String
		start: { type: Date,  default: Date.now } # when Date.now > start students can attempt
		end: { type: Date } # when Date.now > end students can't attempt anylonger
		tries: { type: Number, default: 1 } # tries per student
		allowLate: { type: Boolean, default: false } # allow late submissions or not
		totalPoints: Number
		# OPTIONAL
		body: String # Require's text
		files: Buffer # Require's file(s)?
	}
	Attempt = new Schema {
		# AUTOCREATED
		author: { type: String, +required }
		timestamp: { type: Date, default: Date.now } # submission time
		# REQUIRED
		text: String # student attempt text
		files: Buffer # student attempt file(s)?
	}
	Grade = new Schema {
		# AUTOCREATED
		# _id
		author: { type: String, +required }
		timestamp: { type: Date, default: Date.now }
		# REQUIRED
		attempt: 
		assignment: 
		type: { type: String } #, match: /^(exam|assign)$/i },
		# OPTIONAL
		points: Number # earned points
		total: Number # total points
		id: Number # exam/assign index
		try: Number # attempt index
	}
	# Blog/Conference Schemas
	Thread = new Schema {
		# AUTOCREATED
		# _id
		author: { type: String, +required }
		timestamp: { type: Date, default: Date.now }
		# REQUIRED
		title: String # Thread name
		thread: String # Parent Thread
	}
	Post = new Schema {
		# AUTOCREATED
		# _id
		author: { type: String, +required }
		timestamp: { type: Date, default: Date.now }
		# REQUIRED
		course: String # course uuid for faster lookups
		text: String
		type: String # blog/conference
		school: String # school name
		# OPTIONAL
		title: String
		files: Buffer
		tags: []
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
