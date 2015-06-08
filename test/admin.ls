require! {
	"async"
	"chai" # assert lib
	"del" # delete
	"lodash"
	"moment"
	"mongoose"
	"supertest" # request lib
}
app = require "../lib/app"
ObjectId = mongoose.Types.ObjectId
_ = lodash
req = supertest
expect = chai.expect
assert = chai.assert
should = chai.should!
outside = req.agent app
student = req.agent app
faculty = req.agent app
admin = req.agent app
ObjectId = mongoose.Types.ObjectId
_ = lodash
Course = mongoose.models.Course
User = mongoose.models.User
describe "Admin", (...)->
	before (done)->
		student
			.post "/login"
			.send {
				"username": "student"
				"password": "password"
			}
			.end (err, res)->
				expect res.status .to.equal 302
				done err
	before (done)->
		faculty
			.post "/login"
			.send {
				"username":"faculty"
				"password":"password"
			}
			.end (err, res)->
				expect res.status .to.equal 302
				done!
	before (done)->
		admin
			.post "/login"
			.send {
				"username":"admin"
				"password":"password"
			}
			.end (err, res)->
				expect res.status .to.equal 302
				done!
	it "should return the admin dashboard", (done)->
		admin
			.get "/admin"
			.end (err, res)->
				expect res.status .to.equal 200
				done err
	describe "Search", (...)->
		it "should return a search page", (done)->
			admin
				.get "/admin/?action=search"
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should allow an admin to search for a user", (done)->
			admin
				.post "/admin/?action=search&type=user"
				.send {
					"id": "1"
					"username": "student"
					"email": "student@kean.edu"
				}
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should allow an admin to search for a student", (done)->
			admin
				.post "/admin/?action=search&type=student"
				.send {
					"id": "1"
					"username": "student"
					"email": "student@kean.edu"
				}
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should allow an admin to search for a faculty", (done)->
			admin
				.post "/admin/?action=search&type=faculty"
				.send {
					"id": "2"
					"username": "faculty"
					"email": "faculty@kean.edu"
				}
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should allow an admin to search for a admin", (done)->
			admin
				.post "/admin/?action=search&type=admin"
				.send {
					"id": "3"
					"username": "admin"
					"email": "admin@kean.edu"
				}
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should allow an admin to search for a course", (done)->
			admin
				.post "/admin/?action=search&type=course"
				.send {
					"title":"Intro to Java"
				}
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should not care where type is coming from (body)", (done)->
			err <- async.parallel [
				(para)->
					admin
						.post "/admin/?action=search"
						.send {
							"type": "user"
							"id": "1"
							"username": "student"
							"email": "student@kean.edu"
						}
						.end (err, res)->
							expect res.status .to.equal 200
							para err
				(para)->
					admin
						.post "/admin/?action=search"
						.send {
							"type": "student"
							"id": "1"
							"username": "student"
							"email": "student@kean.edu"
						}
						.end (err, res)->
							expect res.status .to.equal 200
							para err
				(para)->
					admin
						.post "/admin/?action=search"
						.send {
							"type": "faculty"
							"id": "2"
							"username": "faculty"
							"email": "faculty@kean.edu"
						}
						.end (err, res)->
							expect res.status .to.equal 200
							para err
				(para)->
					admin
						.post "/admin/?action=search"
						.send {
							"type": "admin"
							"id": "3"
							"username": "admin"
							"email": "admin@kean.edu"
						}
						.end (err, res)->
							expect res.status .to.equal 200
							para err
				(para)->
					admin
						.post "/admin/?action=search"
						.send {
							"title": "Intro to Java"
						}
						.end (err, res)->
							expect res.status .to.equal 200
							para err
			]
			done err
		it.skip "should not return duplicate results", (done)->
			admin
				.post "/admin/?action=search&type=student"
				.send {
					"id":"1"
					"username":"student"
					"email":"student@kean.edu"
				}
				.end (err, res)->
					expect res.status .to.equal 200
					expect res.body.length .to.equal 1
					done err
	describe "Create User", (...)->
		it "should return a create user page", (done)->
			admin
				.get "/admin/?action=create&type=user"
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should allow an admin to create a student", (done)->
			admin
				.post "/admin/?action=create&type=user"
				.send {
					"id":"1001"
					"username":"adminCreatedStudent"
					"type":"1"
					"password":"password"
					"firstName":"John"
					"middleName":"Middle"
					"lastName":"ThisIsLastName"
					"email":"myemail1@email.com"
				}
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should allow an admin to create a faculty", (done)->
			admin
				.post "/admin/?action=create&type=user"
				.send {
					"id":"1002"
					"username":"adminCreatedFaculty"
					"type":"2"
					"password":"password"
					"firstName":"John"
					"middleName":"Middle"
					"lastName":"ThisIsLastName"
					"email":"myemail2@email.com"
				}
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should allow an admin to create a admin", (done)->
			admin
				.post "/admin/?action=create&type=user"
				.send {
					"id":"1003"
					"username":"adminCreatedAdmin"
					"type":"3"
					"password":"password"
					"firstName":"John"
					"middleName":"Middle"
					"lastName":"ThisIsLastName"
					"email":"myemail3@email.com"
				}
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should not allow an admin to create a user with the same username", (done)->
			admin
				.post "/admin/?action=create&type=user"
				.send {
					"id":"1004"
					"username":"adminCreatedAdmin"
					"type":"3"
					"password":"password"
					"firstName":"John"
					"middleName":"Middle"
					"lastName":"ThisIsLastName"
					"email":"myemailq@email.com"
				}
				.end (err, res)->
					expect res.status .to.equal 400
					done err
		it "should not allow an admin to create a user with the same id", (done)->
			admin
				.post "/admin/?action=create&type=user"
				.send {
					"id":"1003"
					"username":"adminCreatedAdmin1"
					"type":"3"
					"password":"password"
					"firstName":"John"
					"middleName":"Middle"
					"lastName":"ThisIsLastName"
					"email":"myemails@email.com"
				}
				.end (err, res)->
					expect res.status .to.equal 400
					done err
		it "should not allow an admin to create a user with the same email", (done)->
			admin
				.post "/admin/?action=create&type=user"
				.send {
					"id":"1006"
					"username":"adminCreatedAdmin2"
					"type":"3"
					"password":"password"
					"firstName":"John"
					"middleName":"Middle"
					"lastName":"ThisIsLastName"
					"email":"myemail3@email.com"
				}
				.end (err, res)->
					expect res.status .to.equal 400
					done err
		it "should not allow an admin to create an outsider", (done)->
			admin
				.post "/admin/?action=create&type=user"
				.send {
					"id":"1007"
					"username":"adminCreatedOutsider"
					"type":"0"
					"password":"password"
					"firstName":"John"
					"middleName":"Middle"
					"lastName":"ThisIsLastName"
					"email":"myemail@email.com"
				}
				.end (err, res)->
					expect res.status .to.equal 400
					done err
		it "should not allow an admin to create a super admin", (done)->
			admin
				.post "/admin/?action=create&type=user"
				.send {
					"id":"1008"
					"username":"adminCreatedSuperAdmin"
					"type":"4"
					"password":"password"
					"firstName":"John"
					"middleName":"Middle"
					"lastName":"ThisIsLastName"
					"email":"myemail@email.com"
				}
				.end (err, res)->
					expect res.status .to.equal 400
					done err
		it "should not allow an admin to create a user with a tiny password", (done)->
			admin
				.post "/admin/?action=create&type=user"
				.send {
					"id":"1009"
					"username":"adminCreatedTinyPass"
					"type":"2"
					"password":"pass"
					"firstName":"John"
					"middleName":"Middle"
					"lastName":"ThisIsLastName"
					"email":"mydiffemail@email.com"
				}
				.end (err, res)->
					expect res.status .to.equal 400
					done err
	describe "Create Course", (...)->
		it "should return a create course page", (done)->
			admin
				.get "/admin/?action=create&type=course"
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should allow an admin to create a course", (done)->
			admin
				.post "/admin/?action=create&type=course"
				.send {
					"id":"1234"
					"title":"SomethingAwesome"
				}
				.end (err, res)->
					expect res.status .to.equal 200
					done err
	describe "Edit User", (...)->
		it "should return an edit user page", (done)->
			admin
				.get "/admin/?action=edit&type=user"
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should allow an admin to edit a student", (done)->
			admin
				.post "/admin/?hmo=PUT&action=edit&type=user"
				.send {
					"id":"1001"
					"newid":"1001"
					"username":"adminCreatedStudent"
					"type":"1"
					"newusername":"adminCreatedStudent"
					"password":"somethingElse"
					"firstName":"first"
					"middleName":"middle"
					"lastName":"last"
				}
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should allow an admin to edit a faculty", (done)->
			admin
				.post "/admin/?hmo=PUT&action=edit&type=user"
				.send {
					"id":"1002"
					"newid":"1002"
					"username":"adminCreatedFaculty"
					"type":"2"
					"newusername":"adminCreatedFaculty"
					"password":"somethingElse"
					"firstName":"first"
					"middleName":"middle"
					"lastName":"last"
				}
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should allow an admin to edit an admin", (done)->
			admin
				.post "/admin/?hmo=PUT&action=edit&type=user"
				.send {
					"id":"1003"
					"newid":"1003"
					"username":"adminCreatedAdmin"
					"type":"3"
					"newusername":"adminCreatedAdmin"
					"password":"somethingElse"
					"firstName":"first"
					"middleName":"middle"
					"lastName":"last"
				}
				.end (err, res)->
					expect res.status .to.equal 200
					done err
	describe "Edit Course", (...)->
		it "should return an edit course page", (done)->
			admin
				.get "/admin/?action=edit&type=course"
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should allow an admin to edit a course", (done)->
			admin
				.post "/admin/?hmo=PUT&action=edit&type=course"
				.send {
					"id":"1234"
					"newid":"1234"
					"title":"theNewTitle"
				}
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should allow an admin to add a student to a course w/id", (done)->
			admin
				.post "/admin/?hmo=PUT&action=edit&type=addstudent"
				.send {
					"course":"1234"
					"id":"1001"
				}
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should allow an admin to add a student to a course w/username", (done)->
			admin
				.post "/admin/?hmo=PUT&action=edit&type=addstudent"
				.send {
					"course":"1234"
					"username":"adminCreatedStudent"
				}
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should allow an admin to add a faculty to a course w/id", (done)->
			admin
				.post "/admin/?hmo=PUT&action=edit&type=addfaculty"
				.send {
					"course":"1234"
					"id":"1002"
				}
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should allow an admin to add a faculty to a course w/username", (done)->
			admin
				.post "/admin/?hmo=PUT&action=edit&type=addfaculty"
				.send {
					"course":"1234"
					"username":"adminCreatedFaculty"
				}
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should allow an admin to remove a student to a course w/id", (done)->
			admin
				.post "/admin/?hmo=PUT&action=edit&type=rmstudent"
				.send {
					"course":"1234"
					"id":"1001"
				}
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should allow an admin to remove a student to a course w/username", (done)->
			admin
				.post "/admin/?hmo=PUT&action=edit&type=rmstudent"
				.send {
					"course":"1234"
					"username":"adminCreatedStudent"
				}
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should allow an admin to remove a faculty to a course w/id", (done)->
			admin
				.post "/admin/?hmo=PUT&action=edit&type=rmfaculty"
				.send {
					"course":"1234"
					"id":"1002"
				}
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should allow an admin to remove a faculty to a course w/username", (done)->
			admin
				.post "/admin/?hmo=PUT&action=edit&type=rmfaculty"
				.send {
					"course":"1234"
					"username":"adminCreatedFaculty"
				}
				.end (err, res)->
					expect res.status .to.equal 200
					done err
	describe "Delete Course", (...)->
		it.skip "should return a delete course page", (done)->
			admin
				.get "/admin/?action=delete&type=course"
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should allow an admin to delete a course", (done)->
			admin
				.post "/admin/?hmo=DELETE&action=delete&type=course"
				.send {
					"id":"1234"
				}
				.end (err, res)->
					expect res.status .to.equal 200
					done err
	describe "Delete User", (...)->
		it.skip "should return a delete user page", (done)->
			admin
				.get "/admin/?action=delete&type=user"
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should allow an admin to delete a student", (done)->
			admin
				.post "/admin/?hmo=DELETE&action=delete&type=user"
				.send {
					"username":"adminCreatedStudent"
					"type":"1"
				}
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should allow an admin to delete a faculty", (done)->
			admin
				.post "/admin/?hmo=DELETE&action=delete&type=user"
				.send {
					"username":"adminCreatedFaculty"
					"type":"2"
				}
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should allow an admin to delete a admin", (done)->
			admin
				.post "/admin/?hmo=DELETE&action=delete&type=user"
				.send {
					"username":"adminCreatedAdmin"
					"type":"3"
				}
				.end (err, res)->
					expect res.status .to.equal 200
					done err
