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
		school: { type: String, +required, ref: 'School' }
		type: { type: Number, +required, default: 1 }
		firstName: String # first name
		lastName: String # last name
		author: { type: Schema.Types.ObjectId, ref:'User' }
		# OPTIONAL
		# courses: [
		# 	{ type: String, ref: 'Course' } # course id list
		# ]
		id: { type: Number, +unique }, # school issued id
		middleName: String # middle name
	}
	User.index {username: 1}
	Course = new Schema {
		# AUTOCREATED
		# _id
		author: { type: Schema.Types.ObjectId, ref:'User' }
		timestamp: { type: Date, default: Date.now }
		# REQUIRED
		id: { type: String, +required, +unique } # cps1231*02 # unique identifier given by school
		title: { type: String } # Intro to Java
		school: { type: String, +required, ref: 'School' }
		# OPTIONAL
		faculty: [ # faculty usernames
			{ type: Schema.Types.ObjectId, ref:'User' }
		]
		students: [ # student usernames
			{ type: Schema.Types.ObjectId, ref:'User' }
		]
		open: { type: Date }
		close: { type: Date }
	}
	Course.index {timestamp: 1}
	# Course internal Schemas
	Assignment = new Schema {
		# AUTOCREATED
		author: { type: Schema.Types.ObjectId, ref:'User' }
		timestamp: { type: Date, default: Date.now } # created
		# REQUIRED
		course: { type: Schema.Types.ObjectId, +required, ref:'Course' }
		title: String
		start: { type: Date,  default: Date.now } # when Date.now > start students can attempt
		end: { type: Date } # when Date.now > end students can't attempt anylonger
		tries: { type: Number, default: 1 } # tries per student
		allowLate: { type: Boolean, default: false } # allow late submissions or not
		totalPoints: Number
		school: { type: String, +required, ref: 'School' }
		# OPTIONAL
		body: String # Require's text
		files: Buffer # Require's file(s)?
	}
	Assignment.index {timestamp: 1}
	Attempt = new Schema {
		# AUTOCREATED
		author: { type: Schema.Types.ObjectId, ref:'User' }
		timestamp: { type: Date, default: Date.now } # submission time
		# REQUIRED
		assignment: String
		text: String # student attempt text
		files: Buffer # student attempt file(s)?
		school: { type: String, +required, ref: 'School' }
	}
	Attempt.index {timestamp: 1}
	Grade = new Schema {
		# AUTOCREATED
		# _id
		author: { type: Schema.Types.ObjectId, ref:'User' }
		timestamp: { type: Date, default: Date.now }
		# REQUIRED
		attempt: { type: Schema.Types.ObjectId, ref:'Attempt' }
		assignment: { type: Schema.Types.ObjectId, ref:'Assignment' }
		school: { type: String, +required, ref: 'School' }
		try: { type: Number, +required } # attempt index
		type: { type: String, +required } # attempt/final
		# OPTIONAL
		points: Number # earned points
		total: Number # total points
		id: Number # exam/assign index
	}
	Grade.index {timestamp: 1}
	# Blog/Conference Schemas
	Thread = new Schema {
		# AUTOCREATED
		# _id
		author: { type: Schema.Types.ObjectId, ref:'User' }
		timestamp: { type: Date, default: Date.now }
		school: { type: String, +required, ref: 'School' }
		# REQUIRED
		title: String # Thread name
		thread: String # Parent Thread
	}
	Thread.index {timestamp: 1}
	Post = new Schema {
		# AUTOCREATED
		# _id
		author: { type: Schema.Types.ObjectId, +required, ref:'User' }
		authorName: { type: String, +required }
		timestamp: { type: Date, default: Date.now }
		# REQUIRED
		course: { type: Schema.Types.ObjectId, +required, ref:'Course' }
		text: { type: String, +required }
		type: { type: String, +required } # blog/conference
		thread: { type: Schema.Types.ObjectId, ref:'Thread' } # required if type conference
		school: { type: String, +required, ref: 'School' }
		# OPTIONAL
		title: String
		files: Buffer
		tags: []
	}
	Post.index {timestamp: 1}
	module.exports = {
		School: School
		User: User
		Course: Course
		Assignment: Assignment
		Attempt: Attempt
		Grade: Grade
		Thread: Thread
		Post: Post
	}
