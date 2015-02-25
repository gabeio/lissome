module.exports = (app)->
	require! {
		'async'
		'mongoose'
		'winston'
	}
	# mongoose = app.locals.mongoose
	schemas = require('./schemas')(mongoose) # get mongoose schemas
	var school
	User = mongoose.model 'User' schemas.User
	Course = mongoose.model 'Course' schemas.Course
	Assignment = mongoose.model 'Assignment' schemas.Assignment
	Attempt = mongoose.model 'Attempt' schemas.Attempt
	# Grade = mongoose.model 'Grade' schemas.Grade
	Thread = mongoose.model 'Thread' schemas.Thread
	Post = mongoose.model 'Post' schemas.Post
	/* istanbul ignore next if statements because they all catch db crash errors basically. */
	async.parallel [
		->
			err, results <- User.find!.populate('creator').exec (err, users)->
			if err
				winston.error 'User populate:creator'
		->
			err, results <- Course.find!.populate('author').exec
			if err
				winston.error 'Course populate:author'
		->
			err, results <- Course.find!.populate('faculty').exec
			if err
				winston.error 'Course populate:faculty'
		->
			err, results <- Course.find!.populate('students').exec
			if err
				winston.error 'Course populate:students'
		->
			err, results <- Assignment.find!.populate('author').exec
			if err
				winston.error 'Assignment populate:author'
		->
			err, results <- Assignment.find!.populate('course').exec
			if err
				winston.error 'Assignment populate:course'
		->
			err, results <- Attempt.find!.populate('author').exec
			if err
				winston.error 'Attempt populate:author'
		->
			err, results <- Attempt.find!.populate('grader').exec
			if err
				winston.error 'Attempt populate:grader'
		# ->
		# 	err, results <- Grade.find!.populate('author').exec (err, grades)->
		# 	if err
		# 		winston.error 'Grade populate'
		# ->
		# 	err, results <- Grade.find!.populate('attempt').exec (err, grades)->
		# 		if err
		# 			winston.error 'Grade populate'
		# ->
		# 	err, results <- Grade.find!.populate('assignment').exec (err, grades)->
		# 		if err
		# 			winston.error 'Grade populate'
		->
			err, results <- Thread.find!.populate('author').exec
			if err
				winston.error 'Thread populate'
		->
			err, results <- Post.find!.populate('author').exec
			if err
				winston.error 'Post populate'
		->
			err, results <- Post.find!.populate('course').exec
			if err
				winston.error 'Post populate'
		->
			err, results <- Post.find!.populate('thread').exec
			if err
				winston.error 'Post populate'
	]
	# setup school if it's not already setup
	School = mongoose.model 'School', schemas.School
	/* istanbul ignore next fucntion because it only will run if school is not already defined. */
	School.find { name:process.env.school }, (err, school)->
		if err?
			winston.error 'school:find '+util.inspect err
		else
			if !school? and school.length is 0 # if none
				winston.info 'creating new school '+process.env.school
				school = new School {
					name: process.env.school
				}
				err, school <- school.save
	app.locals.models = {
		school: process.env.school
		User: User
		Course: Course
		Assignment: Assignment
		Attempt: Attempt
		# Grade: Grade
		Thread: Thread
		Post: Post
	}
