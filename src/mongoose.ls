module.exports = (app)->
	require! {
		"mongoose"
		"winston"
		"util"
	}
	# mongoose = app.locals.mongoose
	schemas = require("./schemas")(mongoose) # get mongoose schemas
	var school
	User = mongoose.model "User" schemas.User
	Course = mongoose.model "Course" schemas.Course
	Assignment = mongoose.model "Assignment" schemas.Assignment
	Attempt = mongoose.model "Attempt" schemas.Attempt
	Thread = mongoose.model "Thread" schemas.Thread
	Post = mongoose.model "Post" schemas.Post
	# setup school if it's not already setup
	School = mongoose.model "School", schemas.School
	/* istanbul ignore next fucntion because it only will run if school is not already defined. */
	School.find { name:process.env.school }, (err, school)->
		if err?
			winston.error "school:find "+util.inspect err
		else
			if !school? and school.length is 0 # if none
				winston.info "creating new school "+process.env.school
				school = new School {
					name: process.env.school
				}
				err, school <- school.save
