require! {
	mongoose
}
Schema = mongoose.Schema
# Schools
School = new Schema {
	name: { # School name, index: true
		type: String
		requred: true
		unique: true
	}
	students: [Number] # id list of all student
	teachers: [Number] # id list of all teacher
	admins: [Number] # id list of all admin
	courses: [ # id list of all courses
		{
			type: String
			unique: true
		}
	]
}
# School Schemas
Student = new Schema {
	id: { type: Number, required: true, unique: true }, # Student id
	courses: [
		{ type: String, required: true, unique: true }
	], # course id list
	first: String, # first name
	middle: String, # middle name
	last: String, # last name
	username: { type: String, required: true, unique: true }, # unique username
	hash: String, # password bcrypt
}
Teacher = new Schema {
	id: { type: Number, required: true, unique: true }, # Teacher id
	courses: [{ type: String, required: true, unique: true }], # course id
	first: String, # first name
	middle: String, # middle name
	last: String, # last name
	username: { type: String, required: true, unique: true },
	hash: String, # password bcrypt
}
Admin = new Schema {
	id: { type: Number, required: true, unique: true }, # Admin id
	first: String, # first name
	middle: String, # middle name
	last: String, # last name
	username: { type: String, required: true, unique: true }, # username
	hash: String, # password bcrypt
}
Course = new Schema {
	subject: { type: String, required: true } # cps
	id: { type: Number, required: true }, # 1231
	section: String, # *02
	title: { type: String }, # Intro to Java
	conference: [], # Thread
	blog: [], # Post
	exams: [Req], # Req
	assignments: [Req], # Req
	dm: {}, # tid:{sid:[posts]}
	grades: {}, # sid:[Grades]
	teachers: [ # teacher id(s)
		{ type: Number, required: true, unique: true }
	],
	students: [ # student ids
		{ type: Number, required: true, unique: true }
	],
}
# Course Schemas
Req = new Schema {
	text: String, # Require's text
	files: Buffer, # Require's file(s)?
	author: { type: Number, required: true }, # teacher id
	time: { type: Date, default: Date.now }, # created
	start: { type: Date,  default: Date.now }, # start due
	end: { type: Date }, # late time
	tries: { type: Number, default: 1 }, # tries per student
	allowLate: { type: Boolean, default: false }, # allow late submissions or not
	attempts: {}, # student id : [attempt]
	totalPoints: Number,
}
Attempt = new Schema {
	text: String, # student attempt text
	files: Buffer, # student attempt file(s)?
	time: { type: Date, default: Date.now }, # submission time
	comments: [ # teacher comments list
		{
			text: String,
			files: Buffer,
			author: { type: Number, required: true }, # teacher
			time: { type: Date, default: Date.now },
		}
	],
}
Grade = new Schema {
	type: { type: String},#, match: /^(exam|assign)$/i },
	points: Number, # earned points
	total: Number, # total points
	id: Number, # exam/assign index
	try: Number, # attempt index
}
# Blog/Conference Schemas
Thread = new Schema {
	title: String, # Thread name
	posts: [] # Post list
	author: { type: Number, required: true },
}
Post = new Schema {
	text: String,
	files: Buffer,
	author: { type: Number, required: true },
	time: { type: Date, default: Date.now },
}

/*
SchoolM = mongoose.model 'University', SchoolS
StudentM = mongoose.model 'Student', StudentS
TeacherM = mongoose.model 'Teacher', TeacherS
ReqM = mongoose.model 'Req', ReqS
PostM = mongoose.model 'Post', PostS
ThreadM = mongoose.model 'Thread', ThreadS
CourseM = mongoose.model 'Course', CourseS
*/

module.exports = {
	School: mongoose.model 'School', School,
	Student: mongoose.model 'Student', Student,
	Teacher: mongoose.model 'Teacher', Teacher,
	Admin: mongoose.model 'Admin', Admin,
	Course: mongoose.model 'Course', Course,
	Req: mongoose.model 'Req', Req,
	Attempt: mongoose.model 'Attempt', Attempt,
	Grade: mongoose.model 'Grade', Grade,
	Thread: mongoose.model 'Thread', Thread,
	Post: mongoose.model 'Post', Post,
}
