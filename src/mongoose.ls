module.exports = (app)->
	require! {
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
	Grade = mongoose.model 'Grade' schemas.Grade
	Thread = mongoose.model 'Thread' schemas.Thread
	Post = mongoose.model 'Post' schemas.Post
	# setup school if it's not already setup
	School = mongoose.model 'School', schemas.School
	School.find { name:process.env.school }, (err,school)->
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
		Grade: Grade
		Thread: Thread
		Post: Post
	}
