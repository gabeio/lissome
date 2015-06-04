module.exports = (app)->
	require! {
		"async"
		"bcrypt"
		"lodash"
		"mongoose"
		"winston"
	}
	ObjectId = mongoose.Types.ObjectId
	_ = lodash
	Course = mongoose.models.Course
	User = mongoose.models.User
	app
		# @param {ObjectId} [object] should be an ObjectId
		..route "/admin/:object?"
		# @query {string} [action] is what the user wishes to do:
		#   create, edit, delete, etc.
		# @query {string} [type] is what model we are working with
		#   course, user, etc.
		.all (req, res, next)->
			res.locals.needs = 3
			app.locals.authorize req, res, next
		.all (req, res, next)->
			if req.query.action? then req.query.action = req.query.action.toLowerCase!
			if req.query.type? then req.query.type = req.query.type.toLowerCase!
			next!
		.get (req, res, next)->
			switch req.query.action
			| "create"
				res.render "admin/create", {type:req.query.type}
			| "edit"
				res.render "admin/edit", {type:req.query.type}
			| "delete"
				res.render "admin/delete", {type:req.query.type}
			| _
				res.render "admin/default"
		.post (req, res, next)->
			if req.query.action is "create"
				if req.query.type is "user"
					err <- async.waterfall [
						(cont)->
							if req.body.type > 3 or req.body.type < 1
								cont "Invalid User Auth Level"
								# res.status 400
								# res.send "Invalid User Auth Level"
							else
								cont null
						# add more checks here
						(cont)->
							# hash password
							err, result <- bcrypt.hash "password", 10
							cont err, result
						(hash,cont)->
							err,result <- User.find { "username":req.body.username, "type":req.body.type, "school":process.env.school }
							cont err, hash, result
						(hash,result,cont)->
							if result? and result.length > 0
								cont "Student Exists"
							else
								student = new User {
									id: req.body.id
									username: req.body.username
									firstName: req.body.firstName
									lastName: req.body.lastName
									email: req.body.email
									hash: hash
									school: process.env.school
									type: req.body.type
									creator: ObjectId res.locals.uid
								}
								err, student <- student.save
								cont err
					]
					if err
						winston.error err
						res.status = 400
						res.send err
					else
						res.send "OK"
				else if req.query.type is "course"
					err <- async.waterfall [
						# (cont)->
						# add checks
						(cont)->
							err,result <- Course.find { "id":req.body.id, "school":process.env.school }
							cont err, result
						(result,cont)->
							if result? and result.length > 0
								cont "Course Exists"
							else
								course = new Course {
									id: req.body.id
									title: req.body.title
									faculty: []
									students: []
									school: process.env.school
								}
								err, course <- course.save
								cont err
					]
					if err
						winston.error err
						res.status 400
						res.send err
					else
						res.send "OK"
				else
					next!
			else
				next!
		.put (req, res, next)->
			if req.query.action is "edit"
				if req.query.type is "user"
					err <- async.waterfall [
						# (cont)->
						# add checks
						(cont)->
							err,result <- User.find { "username":req.body.username, "school":process.env.school }
							if err
								winston.error err
								cont err
							else
								cont null, result
						(result, cont)->
							cont null
					]
				else if req.query.type is "course"
					err <- async.waterfall [
						# (cont)->
						# add checks
						(cont)->
							err,result <- Course.find { "id":req.body.id, "school":process.env.school }
							if err
								winston.error err
								cont err
							else
								cont null, result
						(result, cont)->
							cont null
					]
				else if req.query.type is "addstudent"
					err <- async.waterfall [
						(cont)->
							err,result <- Course.findOne { "id":req.body.id, "school":process.env.school }
							cont err, result
						(course,cont)->
							course.students.push ObjectId req.body.student
							err <- course.save
							cont err
					]
					if err
						winston.error err
						res.status 400
						res.send err
					else
						res.send "OK"
				else if req.query.type is "addfaculty"
					err <- async.waterfall [
						(cont)->
							err,result <- Course.findOne { "id":req.body.id, "school":process.env.school }
							cont err, result
						(course,cont)->
							course.faculty.push ObjectId req.body.faculty
							err <- course.save
							cont err
					]
					if err
						winston.error err
						res.status 400
						res.send err
					else
						res.send "OK"
				else if req.query.type is "rmstudent"
					err <- async.waterfall [
						(cont)->
							err,result <- Course.findOne { "id":req.body.id, "school":process.env.school }
							cont err, result
						(course,cont)->
							course.students.pop course.students.indexOf req.body.student
							err <- course.save
							cont err
					]
					if err
						winston.error err
						res.status 400
						res.send err
					else
						res.send "OK"
				else if req.query.type is "rmfaculty"
					err <- async.waterfall [
						(cont)->
							err,result <- Course.findOne { "id":req.body.id, "school":process.env.school }
							cont err, result
						(course,cont)->
							course.faculty.pop course.faculty.indexOf req.body.faculty
							err <- course.save
							cont err
					]
					if err
						winston.error err
						res.status 400
						res.send err
					else
						res.send "OK"
				else
					next!
			else
				next!
		.delete (req, res, next)->
			if req.query.action is "delete"
				if req.query.type is "rmstudent"
					err <- async.waterfall [
						# (cont)->
						# add checks
						(cont)->
							err,result <- User.findOneAndRemove { "username":req.body.username, "school":process.env.school }
							if err
								winston.error err
								cont err
							else
								cont null
					]
					res.status 200
					res.send "ok"
				else if req.query.type is "rmfaculty"
					err <- async.waterfall [
						# (cont)->
						# add checks
						(cont)->
							err,result <- Course.findOneAndRemove { "id":req.body.id, "school":process.env.school }
							if err
								winston.error err
								cont err
							else
								cont null
					]
					res.status 200
					res.send "ok"
				else
					next!
			else
				next!
