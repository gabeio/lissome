module.exports = (app)->
	require! {
		"async"
		"bcrypt"
		"lodash"
		"mongoose"
		"winston"
	}
	lower = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]
	upper = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]
	num = ["0","1","2","3","4","5","6","7","8","9"]
	alphanum = lower.concat upper.concat num
	ObjectId = mongoose.Types.ObjectId
	_ = lodash
	Course = mongoose.models.Course
	User = mongoose.models.User
	app
		# @param {ObjectId} [object] should be an ObjectId
		..route "/admin/:object?"
		# @query {string} [action] is what the user wishes to do:
		#   create, edit, delete, etc.
		# @query {string} [type] is the model we are working with
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
			| "search"
				res.render "admin/search"
			| _
				res.render "admin/default"
		.post (req, res, next)->
			if req.query.action is "create"
				if req.query.type is "user"
					err <- async.waterfall [
						(cont)->
							if req.body.type > 3 or req.body.type < 1
								cont "Invalid User Auth Level"
							else
								cont null
						(cont)->
							if req.body.randpassword in [true,"true"]
								newpass = []
								for x from 1 to 7
									index = Math.floor alphanum.length * Math.random()
									newpass.push alphanum[index]
								req.body.password = newpass.join ''
								cont null
							else
								cont null
						# double check password & repeat are the same
						(cont)->
							if req.body.password.length < res.locals.smallpassword
								cont "Password Too Small"
							else
								cont null
						# add more checks here
						(cont)->
							# hash password
							err, result <- bcrypt.hash "password", 10
							cont err, result
						(hash, cont)->
							# check id & username existance seperately
							# both can throw error
							err, result <- async.parallel [
								(para)->
									err, result <- User.find {
										"id":req.body.id
										"type":req.body.type
										"school":process.env.school
									}
									if result? and result.length > 0
										para "User Exists"
									else
										para null
								(para)->
									err, result <- User.find {
										"username":req.body.username
										"type":req.body.type
										"school":process.env.school
									}
									if result? and result.length > 0
										para "User Exists"
									else
										para null
							]
							cont err, hash
						(hash, cont)->
							user = new User {
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
							if req.body.middleName? then user.middleName = req.body.middleName
							err, user <- user.save
							cont err
					]
					if err
						res.status 400
						res.send err
					else
						res.status 200
						res.render "admin/create", { noun:"User", verb:"created", success:"true", type:"user" }
						# res.send "OK"
				else if req.query.type is "course"
					err <- async.waterfall [
						# (cont)->
						# 	add checks
						(cont)->
							err, result <- Course.find {
								"id":req.body.id
								"school":process.env.school
							}
							cont err, result
						(result, cont)->
							# if the course doesn't already exist
							if result? and result.length > 0
								cont "Course Exists"
							else
								# create it
								course = new Course {
									id: req.body.id
									title: req.body.title
									faculty: []
									students: []
									school: process.env.school
									author: ObjectId res.locals.uid
								}
								err, course <- course.save
								cont err
					]
					if err
						winston.error err
						res.status 400
						res.send err
					else
						res.status 200
						res.render "admin/create", { noun:"Course", verb:"created", success:"true", type:"course" }
						# res.send "OK"
				else
					next!
			else
				next!
		.post (req, res, next)->
			if req.query.action is "search"
				if (req.query.type||req.body.type) is "user"
					err, result <- async.parallel [
						(para)->
							err, result <- User.find {
								"id":req.body.id
								"school":process.env.school
							}
							para err, result
						(para)->
							err, result <- User.find {
								"username":req.body.username
								"school":process.env.school
							}
							para err, result
						(para)->
							err, result <- User.find {
								"email":req.body.email
								"school":process.env.school
							}
							para err, result
					]
					if err
						winston.error err
						res.status 400
						res.send err
					else
						res.status 200
						result = _.uniq _.flatten(result), ->
							it.toObject
						,"_id"
						res.render "admin/list" {
							"objs":result
						}
				else if (req.query.type||req.body.type) is "student"
					err, result <- async.parallel [
						(para)->
							err, result <- User.find {
								"id":req.body.id
								"type":1
								"school":process.env.school
							}
							para err, result
						(para)->
							err, result <- User.find {
								"username":req.body.username
								"type":1
								"school":process.env.school
							}
							para err, result
						(para)->
							err, result <- User.find {
								"email":req.body.email
								"type":1
								"school":process.env.school
							}
							para err, result
					]
					if err
						winston.error err
						res.status 400
						res.send err
					else
						res.status 200
						result = _.uniq _.flatten(result), ->
							it.toObject
						,"_id"
						res.render "admin/list" {
							"objs":result
						}
				else if (req.query.type||req.body.type) is "faculty"
					err, result <- async.parallel [
						(para)->
							err, result <- User.find {
								"id":req.body.id
								"type":2
								"school":process.env.school
							}
							para err, result
						(para)->
							err, result <- User.find {
								"username":req.body.username
								"type":2
								"school":process.env.school
							}
							para err, result
						(para)->
							err, result <- User.find {
								"email":req.body.email
								"type":2
								"school":process.env.school
							}
							para err, result
					]
					if err
						winston.error err
						res.status 400
						res.send err
					else
						res.status 200
						result = _.uniq _.flatten(result), ->
							it.toObject
						,"_id"
						res.render "admin/list" {
							"objs":result
						}
				else if (req.query.type||req.body.type) is "admin"
					err, result <- async.parallel [
						(para)->
							err, result <- User.find {
								"id":req.body.id
								"type":3
								"school":process.env.school
							}
							para err, result
						(para)->
							err, result <- User.find {
								"username":req.body.username
								"type":3
								"school":process.env.school
							}
							para err, result
						(para)->
							err, result <- User.find {
								"email":req.body.email
								"type":3
								"school":process.env.school
							}
							para err, result
					]
					if err
						winston.error err
						res.status 400
						res.send err
					else
						res.status 200
						result = _.uniq _.flatten(result), ->
							it.toObject
						,"_id"
						res.render "admin/list" {
							"objs":result
						}
				else if (req.query.type||req.body.type) is "course"
					err, result <- async.parallel [
						(para)->
							err, result <- Course.find {
								"id":req.body.id
								"school":process.env.school
							}
							para err, result
						(para)->
							err, result <- Course.find {
								"title":req.body.title
								"school":process.env.school
							}
							para err, result
					]
					if err
						winston.error err
						res.status 400
						res.send err
					else
						res.status 200
						result = _.uniq _.flatten(result), ->
							it.toObject
						,"_id"
						res.render "admin/list" {
							"objs":result
						}
				else
					res.render "admin/search"
			else
				next!
		.put (req, res, next)->
			if req.query.action is "edit"
				if req.query.type is "user"
					err <- async.waterfall [
						# (cont)->
						# add checks
						(cont)->
							if req.body.type > 3 or req.body.type < 1
								cont "Invalid User Auth Level"
							else
								cont null
						(cont)->
							if req.body.password.length < res.locals.smallpassword
								cont "Password Too Small"
							else
								cont null
						(cont)->
							# hash password
							if req.body.password?
								err, result <- bcrypt.hash "password", 10
								cont err, result
							else
								cont null
						(hash, cont)->
							err, result <- User.findOne {
								"id":req.body.id
								"username":req.body.username
								"type":req.body.type
								"school":process.env.school
							}
							if err
								winston.error err
								cont err
							else
								cont null, hash, result
						(hash, user, cont)->
							if req.body.newid?
								user.id = req.body.newid
							if req.body.newusername?
								user.username = req.body.newusername
							if req.body.password?
								user.hash = hash
							if req.body.type?
								user.type = req.body.type
							if req.body.firstName?
								user.firstName = req.body.middleName
							if req.body.middleName?
								user.middleName = req.body.middleName
							if req.body.lastName?
								user.lastName = req.body.lastName
							err, user <- user.save
							cont err
					]
					if err
						res.status 400
						res.send err
					else
						res.status 200
						res.send "OK"
				else if req.query.type is "course"
					err <- async.waterfall [
						# (cont)->
						# add checks
						(cont)->
							# if we are changing the id do it now then change everything else
							if req.body.newid?
								err, result <- Course.findOneAndUpdate {
									"id":req.body.id
									"school":process.env.school
								}, {
									"id":req.body.newid
								}
								if err
									cont err
								else
									req.body.id = req.body.newid
									cont null
							else
								cont null
						(cont)->
							err, result <- Course.findOne {
								"id":req.body.id
								"school":process.env.school
							}
							if err
								winston.error err
								cont err
							else
								cont null, result
						(course, cont)->
							if req.body.title?
								course.title = req.body.title
							if req.body.open?
								... # TODO: open date/time for classes to show up/visibility
							if req.body.close?
								... # TODO: close date/time for classes to show up/visibility
							err, course <- course.save
							cont err
					]
					if err
						winston.error err
						res.status 400
						res.send err
					else
						res.send "OK"
				else if req.query.type is "addstudent"
					if !req.body.course?
						res.status 400
						res.send "No Course Given"
						res.end!
					err <- async.waterfall [
						(cont)->
							err, result <- Course.findOne {
								"id":req.body.course
								"school":process.env.school
							}
							cont err, result
						(course, cont)->
							if req.body.username?
								err, result <- User.findOne {
									"username":req.body.username
									"type":"1"
									"school":process.env.school
								}
								cont err, result._id, course
							if req.body.id?
								err, result <- User.findOne {
									"id":req.body.id
									"type":"1"
									"school":process.env.school
								}
								cont err, result._id, course
							if req.body._id?
								err, result <- User.findOne {
									"_id":req.body._id
									"type":"1"
									"school":process.env.school
								}
								cont err, result._id, course
						(student, course, cont)->
							course.students.push ObjectId student
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
					if !req.body.course?
						res.status 400
						res.send "No Course Given"
						res.end!
					err <- async.waterfall [
						(cont)->
							err, result <- Course.findOne {
								"id":req.body.course
								"school":process.env.school
							}
							cont err, result
						(course, cont)->
							if req.body.username?
								err, result <- User.findOne {
									"username":req.body.username
									"type":"2"
									"school":process.env.school
								}
								cont err, result._id, course
							if req.body.id?
								err, result <- User.findOne {
									"id":req.body.id
									"type":"2"
									"school":process.env.school
								}
								cont err, result._id, course
							if req.body._id?
								err, result <- User.findOne {
									"_id":req.body._id
									"type":"2"
									"school":process.env.school
								}
								cont err, result._id, course
						(faculty, course, cont)->
							course.faculty.push ObjectId faculty
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
							err, result <- Course.findOne {
								"id":req.body.course
								"school":process.env.school
							}
							cont err, result
						(course, cont)->
							if req.body.username?
								err, result <- User.findOne {
									"username":req.body.username
									"type":"1"
									"school":process.env.school
								}
								cont err, result._id, course
							if req.body.id?
								err, result <- User.findOne {
									"id":req.body.id
									"type":"1"
									"school":process.env.school
								}
								cont err, result._id, course
							if req.body._id?
								err, result <- User.findOne {
									"_id":req.body._id
									"type":"1"
									"school":process.env.school
								}
								cont err, result._id, course
						(student, course, cont)->
							course.students.pop course.students.indexOf student
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
							err, result <- Course.findOne {
								"id":req.body.course
								"school":process.env.school
							}
							cont err, result
						(course, cont)->
							if req.body.username?
								err, result <- User.findOne {
									"username":req.body.username
									"type":"2"
									"school":process.env.school
								}
								cont err, result._id, course
							if req.body.id?
								err, result <- User.findOne {
									"id":req.body.id
									"type":"2"
									"school":process.env.school
								}
								cont err, result._id, course
							if req.body._id?
								err, result <- User.findOne {
									"_id":req.body._id
									"type":"2"
									"school":process.env.school
								}
								cont err, result._id, course
						(faculty, course, cont)->
							course.faculty.pop course.faculty.indexOf faculty
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
				if req.query.type is "user"
					err <- async.waterfall [
						(cont)->
							err, result <- User.findOneAndRemove {
								"username":req.body.username
								"school":process.env.school
							}
							if err
								winston.error err
								cont err
							else
								cont null
					]
					res.status 200
					res.send "ok"
				else if req.query.type is "course"
					err <- async.waterfall [
						(cont)->
							err, result <- Course.findOneAndRemove {
								"id":req.body.id
								"school":process.env.school
							}
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
