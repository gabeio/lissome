require! {
	"express"
	"async"
	"bcrypt"
	"lodash"
	"mongoose"
	"winston"
	"./app"
}
parser = app.locals.multer.fields []
lower = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]
upper = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]
num = ["0","1","2","3","4","5","6","7","8","9"]
alphanum = lower ++ upper ++ num
ObjectId = mongoose.Types.ObjectId
_ = lodash
Course = mongoose.models.Course
User = mongoose.models.User
router = express.Router!
router
	# @param {ObjectId} [object] *should* be an ObjectId
	..route "/:object?"
	# @query {string} [action] is what the user wishes to do:
	#   create, edit, delete, etc.
	# @query {string} [type] is the model we are working with
	#   course, user, etc.
	.all (req, res, next)->
		res.locals.needs = 3
		app.locals.authorize req, res, next
	.all (req, res, next)->
		# force all actions to be lowercase
		if req.query.action? then req.query.action = req.query.action.toLowerCase!
		# get type from body and query
		if req.query.type? or req.body.type?
			res.locals.type = (req.query.type||req.body.type)
		# force all type to be lowercase
		if res.locals.type? then res.locals.type = res.locals.type.toLowerCase!
		next!
	.get (req, res, next)->
		switch req.query.action
		| "create"
			res.render "admin/create", { type:res.locals.type, csrf: req.csrfToken! }
		| "edit"
			res.render "admin/edit", { type:res.locals.type, csrf: req.csrfToken! }
		| "delete"
			res.render "admin/delete", { type:res.locals.type, csrf: req.csrfToken! }
		| "search"
			res.render "admin/search", { csrf: req.csrfToken! }
		| "addstudent"
			res.render "admin/addstudent", { csrf: req.csrfToken! }
		| "addfaculty"
			res.render "admin/addfaculty", { csrf: req.csrfToken! }
		| "rmstudent"
			res.render "admin/rmstudent", { csrf: req.csrfToken! }
		| "rmfaculty"
			res.render "admin/rmfaculty", { csrf: req.csrfToken! }
		| _
			res.render "admin/default", { csrf: req.csrfToken! }
	.post parser, (req, res, next)->
		if req.query.action is "create"
			if res.locals.type is "user"
				err <- async.waterfall [
					(cont)->
						# checking new user's level is within client levels
						if req.body.level > 3 or req.body.level < 1
							cont "Invalid User Auth Level"
						else
							cont null
					(cont)->
						# if admin wants a random password
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
						# assure password is not smaller than small limit
						if req.body.password.length < app.locals.smallpassword
							cont "Password Too Small"
						else
							cont null
					# add more checks here
					(cont)->
						# hash password
						err, result <- bcrypt.hash "password", 10
						cont err, result
					(hash, cont)->
						# check id & username existance
						err, result <- async.parallel [
							(para)->
								err, result <- User.find {
									"id":req.body.id
									"type":req.body.level
									"school":app.locals.school
								}
								if result? and result.length > 0
									para "User Exists"
								else
									para null
							(para)->
								err, result <- User.find {
									"username":req.body.username
									"type":req.body.level
									"school":app.locals.school
								}
								if result? and result.length > 0
									para "User Exists"
								else
									para null
							(para)->
								err, result <- User.find {
									"email": req.body.email
									"type":req.body.level
									"school":app.locals.school
								}
								if result? and result.length > 0
									para "User Exists"
								else
									para null
						]
						cont err, hash
					(hash, cont)->
						# if everything checks out create the user
						user = new User {
							id: req.body.id
							username: req.body.username
							firstName: req.body.firstName
							lastName: req.body.lastName
							email: req.body.email
							hash: hash
							school: app.locals.school
							type: req.body.level
							creator: ObjectId res.locals.uid
						}
						user.middleName? = req.body.middleName
						err, user <- user.save
						cont err
				]
				if err
					winston.error err
					res.status 400
					res.send err
				else
					res.status 200
					res.render "admin/create", { noun:"User", verb:"created", success:"true", type:"user", csrf: req.csrfToken! }
					# res.send "OK"
			else if res.locals.type is "course"
				err <- async.waterfall [
					# (cont)->
					# 	add checks
					(cont)->
						# see if the course id already exists
						err, result <- Course.find {
							"id":req.body.id
							"school":app.locals.school
						}
						if result? and result.length > 0
							cont "Course Exists"
						else
							cont err, result
					(result, cont)->
						# create the course
						course = new Course {
							id: req.body.id
							title: req.body.title
							faculty: []
							students: []
							school: app.locals.school
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
					res.render "admin/create", { noun:"Course", verb:"created", success:"true", type:"course", csrf: req.csrfToken! }
					# res.send "OK"
			else
				next!
		else
			next!
	.post parser, (req, res, next)->
		if req.query.action is "search"
			if res.locals.type is "user"
				err, result <- async.parallel [
					(para)->
						err, result <- User.find {
							"id":req.body.id
							"school":app.locals.school
						}
						.lean!
						.exec
						para err, result
					(para)->
						err, result <- User.find {
							"username":req.body.username
							"school":app.locals.school
						}
						.lean!
						.exec
						para err, result
					(para)->
						err, result <- User.find {
							"email":req.body.email
							"school":app.locals.school
						}
						.lean!
						.exec
						para err, result
				]
				if err
					winston.error err
					res.status 400
					res.send err
				else
					res.status 200
					result = _.uniq _.flatten(result),"_id"
					res.render "admin/list" { objs: result, type: res.locals.type }
			else if res.locals.type is "student"
				err, result <- async.parallel [
					(para)->
						err, result <- User.find {
							"id": req.body.id
							"type": 1
							"school": app.locals.school
						}
						.lean!
						.exec
						para err, result
					(para)->
						err, result <- User.find {
							"username": req.body.username
							"type": 1
							"school": app.locals.school
						}
						.lean!
						.exec
						para err, result
					(para)->
						err, result <- User.find {
							"email": req.body.email
							"type": 1
							"school": app.locals.school
						}
						.lean!
						.exec
						para err, result
				]
				if err
					winston.error err
					res.status 400
					res.send err
				else
					res.status 200
					result = _.uniq _.flatten(result),"_id"
					res.render "admin/list" { objs: result, type: res.locals.type }
			else if res.locals.type is "faculty"
				err, result <- async.parallel [
					(para)->
						err, result <- User.find {
							"id": req.body.id
							"type": 2
							"school": app.locals.school
						}
						.lean!
						.exec
						para err, result
					(para)->
						err, result <- User.find {
							"username": req.body.username
							"type": 2
							"school": app.locals.school
						}
						.lean!
						.exec
						para err, result
					(para)->
						err, result <- User.find {
							"email": req.body.email
							"type": 2
							"school": app.locals.school
						}
						.lean!
						.exec
						para err, result
				]
				if err
					winston.error err
					res.status 400
					res.send err
				else
					res.status 200
					result = _.uniq _.flatten(result),"_id"
					res.render "admin/list" { objs: result, type: res.locals.type }
			else if res.locals.type is "admin"
				err, result <- async.parallel [
					(para)->
						err, result <- User.find {
							"id": req.body.id
							"type": 3
							"school": app.locals.school
						}
						.lean!
						.exec
						para err, result
					(para)->
						err, result <- User.find {
							"username": req.body.username
							"type": 3
							"school": app.locals.school
						}
						.lean!
						.exec
						para err, result
					(para)->
						err, result <- User.find {
							"email": req.body.email
							"type": 3
							"school": app.locals.school
						}
						.lean!
						.exec
						para err, result
				]
				if err
					winston.error err
					res.status 400
					res.send err
				else
					res.status 200
					result = _.uniq _.flatten(result),"_id"
					res.render "admin/create" { objs: result, type: res.locals.type }
			else if res.locals.type is "course"
				err, result <- async.parallel [
					(para)->
						err, result <- Course.find {
							"id": req.body.id
							"school": app.locals.school
						}
						.lean!
						.exec
						para err, result
					(para)->
						err, result <- Course.find {
							"title": req.body.title
							"school": app.locals.school
						}
						.lean!
						.exec
						para err, result
				]
				if err
					winston.error err
					res.status 400
					res.send err
				else
					res.status 200
					result = _.uniq _.flatten(result),"_id"
					res.render "admin/list" { objs: result, type: res.locals.type }
			else
				res.render "admin/search", { csrf: req.csrfToken! }
		else
			next!
	.post parser, (req, res, next)->
		if req.query.action is "addstudent"
			# *SEARCH* for student to add to course
			if !req.params.object?
				res.status 400
				res.send "No Course Given"
			else
				err, result <- async.parallel [
					(para)->
						if req.body.name?
							err, result <- User.findOne {
								"name": new RegExp req.body.name, "i"
								"type": 1
								"school": app.locals.school
							}
							.lean!
							.exec
							para err, result
					(para)->
						if req.body.id?
							err, result <- User.findOne {
								"id": req.body.id
								"type": 1
								"school": app.locals.school
							}
							.lean!
							.exec
							para err, result
					(para)->
						if req.body._id?
							err, result <- User.findOne {
								"_id": req.body._id
								"type": 1
								"school": app.locals.school
							}
							.lean!
							.exec
							para err, result
					(para)->
						if req.body.username?
							err, result <- User.findOne {
								"username": req.body.username
								"type": 1
								"school": app.locals.school
							}
							.lean!
							.exec
							para err, result
				]
				if err?
					winston.error err
					res.status 400
					res.send err
				else
					res.status 200
					result = _.uniq _.flatten(result),"_id"
					res.render "admin/addstudent", { objs: result, csrf: req.csrfToken! }
		else if req.query.action is "addfaculty"
			# *SEARCH* for faculty to add
			if !req.params.object?
				res.status 400
				res.send "No Course Given"
			else
				err, result <- async.parallel [
					(para)->
						if req.body.name?
							err, result <- User.findOne {
								"name": new RegExp req.body.name, "i"
								"type": 2
								"school": app.locals.school
							}
							.lean!
							.exec
							para err, result

					(para)->
						if req.body.id?
							err, result <- User.findOne {
								"id": req.body.id
								"type": 2
								"school": app.locals.school
							}
							.lean!
							.exec
							para err, result
					(para)->
						if req.body._id?
							err, result <- User.findOne {
								"_id": req.body._id
								"type": 2
								"school": app.locals.school
							}
							.lean!
							.exec
							para err, result
					(para)->
						if req.body.username?
							err, result <- User.findOne {
								"username": req.body.username
								"type": 2
								"school": app.locals.school
							}
							.lean!
							.exec
							para err, result
				]
				if err?
					winston.error err
					res.status 400
					res.send err
				else
					res.status 200
					result = _.uniq _.flatten(result),"_id"
					res.render "admin/addstudent", { objs: result, csrf: req.csrfToken! }
		else if req.query.action is "rmstudent"
			# *SEARCH* for student to rm
			...
		else if req.query.action is "rmfaculty"
			# *SEARCH* for faculty to rm
			...
		else
			next!
	.put parser, (req, res, next)->
		if req.query.action is "edit"
			if res.locals.type is "user"
				err <- async.waterfall [
					# (cont)->
					# add checks
					(cont)->
						if req.body.level > 3 or req.body.level < 1
							cont "Invalid User Auth Level"
						else
							cont null
					(cont)->
						if req.body.password.length < app.locals.smallpassword
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
							"id": req.body.id
							"username": req.body.username
							"type": req.body.level
							"school": app.locals.school
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
						if req.body.level?
							user.type = req.body.level
						if req.body.firstName?
							user.firstName = req.body.firstName
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
			else if res.locals.type is "course"
				err <- async.waterfall [
					# (cont)->
					# add checks
					(cont)->
						# if we are changing the id do it now then change everything else
						if req.body.newid?
							err, result <- Course.findOneAndUpdate {
								"id": req.params.object
								"school": app.locals.school
							}, {
								"id": req.body.newid
							}
							if err
								cont err
							else
								req.params.object = req.body.newid
								cont null
						else
							cont null
					(cont)->
						err, result <- Course.findOne {
							"id": req.params.object
							"school": app.locals.school
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
			else if res.locals.type is "addstudent"
				# add student to course
				if !req.params.object?
					res.status 400
					res.send "No Course Given"
					res.end!
				else
					err <- async.waterfall [
						(cont)->
							err, result <- Course.findOne {
								"id": req.params.object
								"school": app.locals.school
							}
							cont err, result
						(course, cont)->
							if req.body.username?
								err, result <- User.findOne {
									"username": req.body.username
									"type": 1
									"school": app.locals.school
								}
								cont err, result._id, course
							else if req.body.id?
								err, result <- User.findOne {
									"id": req.body.id
									"type": 1
									"school": app.locals.school
								}
								cont err, result._id, course
							else if req.body._id?
								err, result <- User.findOne {
									"_id": req.body._id
									"type": 1
									"school": app.locals.school
								}
								cont err, result._id, course
							else
								cont "No Student Given"
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
			else if res.locals.type is "addfaculty"
				# add faculty to course
				if !req.params.object?
					res.status 400
					res.send "No Course Given"
					res.end!
				else
					err <- async.waterfall [
						(cont)->
							err, result <- Course.findOne {
								"id": req.params.object
								"school": app.locals.school
							}
							cont err, result
						(course, cont)->
							if req.body.username?
								err, result <- User.findOne {
									"username": req.body.username
									"type": 2
									"school": app.locals.school
								}
								cont err, result._id, course
							else if req.body.id?
								err, result <- User.findOne {
									"id": req.body.id
									"type": 2
									"school": app.locals.school
								}
								cont err, result._id, course
							else if req.body._id?
								err, result <- User.findOne {
									"_id": req.body._id
									"type": 2
									"school": app.locals.school
								}
								cont err, result._id, course
							else
								cont "No Faculty Given"
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
			else if res.locals.type is "rmstudent"
				# rm student to course
				err <- async.waterfall [
					(cont)->
						err, result <- Course.findOne {
							"id": req.params.object
							"school": app.locals.school
						}
						cont err, result
					(course, cont)->
						if req.body.username?
							err, result <- User.findOne {
								"username": req.body.username
								"type": 1
								"school": app.locals.school
							}
							cont err, result._id, course
						else if req.body.id?
							err, result <- User.findOne {
								"id": req.body.id
								"type": 1
								"school": app.locals.school
							}
							cont err, result._id, course
						else if req.body._id?
							err, result <- User.findOne {
								"_id": req.body._id
								"type": 1
								"school": app.locals.school
							}
							cont err, result._id, course
						else
							cont "No Student Given"
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
			else if res.locals.type is "rmfaculty"
				# rm faculty to course
				err <- async.waterfall [
					(cont)->
						err, result <- Course.findOne {
							"id": req.params.object
							"school": app.locals.school
						}
						cont err, result
					(course, cont)->
						if req.body.username?
							err, result <- User.findOne {
								"username": req.body.username
								"type": 2
								"school": app.locals.school
							}
							cont err, result._id, course
						else if req.body.id?
							err, result <- User.findOne {
								"id": req.body.id
								"type": 2
								"school": app.locals.school
							}
							cont err, result._id, course
						else if req.body._id?
							err, result <- User.findOne {
								"_id": req.body._id
								"type": 2
								"school": app.locals.school
							}
							cont err, result._id, course
						else
							cont "No Faculty Given"
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
	.delete parser, (req, res, next)->
		if req.query.action is "delete"
			if res.locals.type is "user"
				err <- async.waterfall [
					(cont)->
						err, result <- User.findOneAndRemove {
							"type": req.body.level
							"username": req.params.object
							"school": app.locals.school
						}
						if err
							cont err
						else if !result? or result.length < 1
							cont "Could Not Find Course To Delete"
						else
							cont null
				]
				if err
					winston.error err
					res.status 400
					res.send err
				else
					res.status 200
					res.send "ok"
			else if res.locals.type is "course"
				err <- async.waterfall [
					(cont)->
						err, result <- Course.findOneAndRemove {
							"id": req.params.object
							"school": app.locals.school
						}
						if err
							cont err
						else if !result? or result.length < 1
							cont "Could Not Find Course To Delete"
						else
							cont null
				]
				if err
					console.log err
					winston.error err
					res.status 400
					res.send err
				else
					res.status 200
					res.send "ok"
			else
				next!
		else
			next!

module.exports = router
