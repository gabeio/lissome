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
describe "Admin Module", (...)->
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
	describe "Dashboard", (...)->
		describe "(User: Admin)", (...)->
			it "should return the admin dashboard", (done)->
				admin
					.get "/admin"
					.end (err, res)->
						expect res.status .to.equal 200
						done err
		describe "(User: Faculty)", (...)->
			it "should not return the admin dashboard", (done)->
				faculty
					.get "/admin"
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
		describe "(User: Student)", (...)->
			it "should not return the admin dashboard", (done)->
				student
					.get "/admin"
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
		describe "(User: Outside)", (...)->
			it "should not return the admin dashboard", (done)->
				outside
					.get "/admin"
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
	describe "Search", (...)->
		describe "(User: Admin)", (...)->
			it "should return a search page", (done)->
				admin
					.get "/admin/?action=search"
					.end (err, res)->
						expect res.status .to.equal 200
						done err
			it "should search for a user", (done)->
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
			it "should search for a student", (done)->
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
			it "should search for a faculty", (done)->
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
			it "should search for a admin", (done)->
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
			it "should search for a course", (done)->
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
			it "should not do anything for put action=search", (done)->
				err <- async.parallel [
					(para)->
						admin
							.put "/admin/?action=search&type=course"
							.send {
								"title":"Intro to Java"
							}
							.expect 404
							.end (err, res)->
								para err
					(para)->
						admin
							.put "/admin/?action=search&type=user"
							.send {
								"id":"1"
							}
							.expect 404
							.end (err, res)->
								para err
				]
				done err
			it "should not do anything for delete action=search", (done)->
				err <- async.parallel [
					(para)->
						admin
							.delete "/admin/?action=search&type=course"
							.send {
								"title":"Intro to Java"
							}
							.expect 404
							.end (err, res)->
								para err
					(para)->
						admin
							.delete "/admin/?action=search&type=user"
							.send {
								"id":"1"
							}
							.expect 404
							.end (err, res)->
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
		describe "(User: Faculty)", (...)->
			it "should not return a search page", (done)->
				faculty
					.get "/admin/?action=search"
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should now allow a faculty to search", (done)->
				err <- async.parallel [
					(para)->
						faculty
							.post "/admin/?action=search&type=user"
							.send {
								"id": "1"
								"username": "student"
								"email": "student@kean.edu"
							}
							.end (err, res)->
								expect res.status .to.not.equal 200
								para err
					(para)->
						faculty
							.post "/admin/?action=search&type=course"
							.send {
								"title": "Intro to Java"
							}
							.end (err, res)->
								expect res.status .to.not.equal 200
								para err
				]
				done err
		describe "(User: Student)", (...)->
			it "should not return a search page", (done)->
				student
					.get "/admin/?action=search"
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should now allow a student to search", (done)->
				err <- async.parallel [
					(para)->
						student
							.post "/admin/?action=search&type=user"
							.send {
								"id": "1"
								"username": "student"
								"email": "student@kean.edu"
							}
							.end (err, res)->
								expect res.status .to.not.equal 200
								para err
					(para)->
						student
							.post "/admin/?action=search&type=course"
							.send {
								"title": "Intro to Java"
							}
							.end (err, res)->
								expect res.status .to.not.equal 200
								para err
				]
				done err
		describe "(User: Outside)", (...)->
			it "should not return a search page", (done)->
				outside
					.get "/admin/?action=search"
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should now allow a outside user to search", (done)->
				err <- async.parallel [
					(para)->
						outside
							.post "/admin/?action=search&type=user"
							.send {
								"id": "1"
								"username": "student"
								"email": "student@kean.edu"
							}
							.end (err, res)->
								expect res.status .to.not.equal 200
								para err
					(para)->
						outside
							.post "/admin/?action=search&type=course"
							.send {
								"title": "Intro to Java"
							}
							.end (err, res)->
								expect res.status .to.not.equal 200
								para err
				]
				done err
	describe "Create User", (...)->
		describe "(User: Admin)", (...)->
			it "should return a create user page", (done)->
				admin
					.get "/admin/?action=create&type=user"
					.end (err, res)->
						expect res.status .to.equal 200
						done err
			it "should create a student", (done)->
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
			it "should create a faculty", (done)->
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
			it "should create a admin", (done)->
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
			it "should not create a user with the same username", (done)->
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
			it "should not create a user with the same id", (done)->
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
			it "should not create a user with the same email", (done)->
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
			it "should not create an outsider", (done)->
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
			it "should not create a super admin", (done)->
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
			it "should not create a user with a tiny password", (done)->
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
			it "should not do anything for put action=create", (done)->
				admin
					.put "/admin/?action=create&type=user"
					.send {
						"id":"1009"
						"username":"adminCreatedTinyPass"
						"type":"2"
						"password":"password"
						"firstName":"John"
						"middleName":"Middle"
						"lastName":"ThisIsLastName"
						"email":"mydiffemail@email.com"
					}
					.end (err, res)->
						expect res.status .to.equal 404
						done err
			it "should not do anything for delete action=create", (done)->
				admin
					.delete "/admin/?action=create&type=user"
					.send {
						"id":"1009"
						"username":"adminCreatedTinyPass"
						"type":"2"
						"password":"password"
						"firstName":"John"
						"middleName":"Middle"
						"lastName":"ThisIsLastName"
						"email":"mydiffemail@email.com"
					}
					.end (err, res)->
						expect res.status .to.equal 404
						done err
		describe "(User: Faculty)", (...)->
			it "should return a create user page", (done)->
				faculty
					.get "/admin/?action=create&type=user"
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should create a student", (done)->
				faculty
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
						expect res.status .to.not.equal 200
						done err
			it "should create a faculty", (done)->
				faculty
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
						expect res.status .to.not.equal 200
						done err
			it "should create a admin", (done)->
				faculty
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
						expect res.status .to.not.equal 200
						done err
		describe "(User: Student)", (...)->
			it "should return a create user page", (done)->
				student
					.get "/admin/?action=create&type=user"
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should create a student", (done)->
				student
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
						expect res.status .to.not.equal 200
						done err
			it "should create a faculty", (done)->
				student
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
						expect res.status .to.not.equal 200
						done err
			it "should create a admin", (done)->
				student
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
						expect res.status .to.not.equal 200
						done err
		describe "(User: Outside)", (...)->
			it "should return a create user page", (done)->
				outside
					.get "/admin/?action=create&type=user"
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should create a student", (done)->
				outside
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
						expect res.status .to.not.equal 200
						done err
			it "should create a faculty", (done)->
				outside
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
						expect res.status .to.not.equal 200
						done err
			it "should create a admin", (done)->
				outside
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
						expect res.status .to.not.equal 200
						done err
	describe "Create Course", (...)->
		describe "(User: Admin)", (...)->
			it "should return a create course page", (done)->
				admin
					.get "/admin/?action=create&type=course"
					.end (err, res)->
						expect res.status .to.equal 200
						done err
			it "should create a course", (done)->
				admin
					.post "/admin/?action=create&type=course"
					.send {
						"id":"1234"
						"title":"SomethingAwesome"
					}
					.end (err, res)->
						expect res.status .to.equal 200
						done err
		describe "(User: Facult)", (...)->
			it "should return a create course page", (done)->
				faculty
					.get "/admin/?action=create&type=course"
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should create a course", (done)->
				faculty
					.post "/admin/?action=create&type=course"
					.send {
						"id":"1234"
						"title":"SomethingAwesome"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
		describe "(User: Student)", (...)->
			it "should return a create course page", (done)->
				student
					.get "/admin/?action=create&type=course"
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should create a course", (done)->
				student
					.post "/admin/?action=create&type=course"
					.send {
						"id":"1234"
						"title":"SomethingAwesome"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
		describe "(User: Outside)", (...)->
			it "should return a create course page", (done)->
				outside
					.get "/admin/?action=create&type=course"
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should create a course", (done)->
				outside
					.post "/admin/?action=create&type=course"
					.send {
						"id":"1234"
						"title":"SomethingAwesome"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
	describe "Edit User", (...)->
		describe "(User: Admin)", (...)->
			it "should return an edit user page", (done)->
				admin
					.get "/admin/?action=edit&type=user"
					.end (err, res)->
						expect res.status .to.equal 200
						done err
			it "should edit a student", (done)->
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
			it "should edit a faculty", (done)->
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
			it "should edit an admin", (done)->
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
		describe "(User: Faculty)", (...)->
			it "should not return an edit user page", (done)->
				faculty
					.get "/admin/?action=edit&type=user"
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not edit a student", (done)->
				faculty
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
						expect res.status .to.not.equal 200
						done err
			it "should not edit a faculty", (done)->
				faculty
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
						expect res.status .to.not.equal 200
						done err
			it "should not edit an admin", (done)->
				faculty
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
						expect res.status .to.not.equal 200
						done err
		describe "(User: Student)", (...)->
			it "should return an edit user page", (done)->
				student
					.get "/admin/?action=edit&type=user"
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should edit a student", (done)->
				student
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
						expect res.status .to.not.equal 200
						done err
			it "should edit a faculty", (done)->
				student
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
						expect res.status .to.not.equal 200
						done err
			it "should edit an admin", (done)->
				student
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
						expect res.status .to.not.equal 200
						done err
		describe "(User: Outside)", (...)->
			it "should return an edit user page", (done)->
				outside
					.get "/admin/?action=edit&type=user"
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should edit a student", (done)->
				outside
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
						expect res.status .to.not.equal 200
						done err
			it "should edit a faculty", (done)->
				outside
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
						expect res.status .to.not.equal 200
						done err
			it "should edit an admin", (done)->
				outside
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
						expect res.status .to.not.equal 200
						done err
	describe "Edit Course", (...)->
		describe "(User: Admin)", (...)->
			it "should return an edit course page", (done)->
				admin
					.get "/admin/?action=edit&type=course"
					.end (err, res)->
						expect res.status .to.equal 200
						done err
			it "should edit a course", (done)->
				admin
					.post "/admin/1234?hmo=PUT&action=edit&type=course"
					.send {
						# "id":"1234"
						"newid":"1234"
						"title":"theNewTitle"
					}
					.end (err, res)->
						expect res.status .to.equal 200
						done err
			it "should add a student to a course w/id", (done)->
				admin
					.post "/admin/1234?hmo=PUT&action=edit&type=addstudent"
					.send {
						# "course":"1234"
						"id":"1001"
					}
					.end (err, res)->
						expect res.status .to.equal 200
						done err
			it "should add a student to a course w/username", (done)->
				admin
					.post "/admin/1234?hmo=PUT&action=edit&type=addstudent"
					.send {
						# "course":"1234"
						"username":"adminCreatedStudent"
					}
					.end (err, res)->
						expect res.status .to.equal 200
						done err
			it "should add a faculty to a course w/id", (done)->
				admin
					.post "/admin/1234?hmo=PUT&action=edit&type=addfaculty"
					.send {
						# "course":"1234"
						"id":"1002"
					}
					.end (err, res)->
						expect res.status .to.equal 200
						done err
			it "should add a faculty to a course w/username", (done)->
				admin
					.post "/admin/1234?hmo=PUT&action=edit&type=addfaculty"
					.send {
						# "course":"1234"
						"username":"adminCreatedFaculty"
					}
					.end (err, res)->
						expect res.status .to.equal 200
						done err
			it "should remove a student from a course w/id", (done)->
				admin
					.post "/admin/1234?hmo=PUT&action=edit&type=rmstudent"
					.send {
						"course":"1234"
						"id":"1001"
					}
					.end (err, res)->
						expect res.status .to.equal 200
						done err
			it "should remove a student from a course w/username", (done)->
				admin
					.post "/admin/1234?hmo=PUT&action=edit&type=rmstudent"
					.send {
						"course":"1234"
						"username":"adminCreatedStudent"
					}
					.end (err, res)->
						expect res.status .to.equal 200
						done err
			it "should remove a faculty from a course w/id", (done)->
				admin
					.post "/admin/1234?hmo=PUT&action=edit&type=rmfaculty"
					.send {
						"course":"1234"
						"id":"1002"
					}
					.end (err, res)->
						expect res.status .to.equal 200
						done err
			it "should remove a faculty from a course w/username", (done)->
				admin
					.post "/admin/1234?hmo=PUT&action=edit&type=rmfaculty"
					.send {
						"course":"1234"
						"username":"adminCreatedFaculty"
					}
					.end (err, res)->
						expect res.status .to.equal 200
						done err
		describe "(User: Faculty)", (...)->
			it "should not return an edit course page", (done)->
				faculty
					.get "/admin/?action=edit&type=course"
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not edit a course", (done)->
				faculty
					.post "/admin/?hmo=PUT&action=edit&type=course"
					.send {
						"id":"1234"
						"newid":"1234"
						"title":"theNewTitle"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not add a student to a course w/id", (done)->
				faculty
					.post "/admin/?hmo=PUT&action=edit&type=addstudent"
					.send {
						"course":"1234"
						"id":"1001"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not add a student to a course w/username", (done)->
				faculty
					.post "/admin/?hmo=PUT&action=edit&type=addstudent"
					.send {
						"course":"1234"
						"username":"adminCreatedStudent"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not add a faculty to a course w/id", (done)->
				faculty
					.post "/admin/?hmo=PUT&action=edit&type=addfaculty"
					.send {
						"course":"1234"
						"id":"1002"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not add a faculty to a course w/username", (done)->
				faculty
					.post "/admin/?hmo=PUT&action=edit&type=addfaculty"
					.send {
						"course":"1234"
						"username":"adminCreatedFaculty"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not remove a student to a course w/id", (done)->
				faculty
					.post "/admin/?hmo=PUT&action=edit&type=rmstudent"
					.send {
						"course":"1234"
						"id":"1001"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not remove a student to a course w/username", (done)->
				faculty
					.post "/admin/?hmo=PUT&action=edit&type=rmstudent"
					.send {
						"course":"1234"
						"username":"adminCreatedStudent"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not remove a faculty to a course w/id", (done)->
				faculty
					.post "/admin/?hmo=PUT&action=edit&type=rmfaculty"
					.send {
						"course":"1234"
						"id":"1002"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not remove a faculty to a course w/username", (done)->
				faculty
					.post "/admin/?hmo=PUT&action=edit&type=rmfaculty"
					.send {
						"course":"1234"
						"username":"adminCreatedFaculty"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
		describe "(User: Student)", (...)->
			it "should not return an edit course page", (done)->
				student
					.get "/admin/?action=edit&type=course"
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not edit a course", (done)->
				student
					.post "/admin/?hmo=PUT&action=edit&type=course"
					.send {
						"id":"1234"
						"newid":"1234"
						"title":"theNewTitle"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not add a student to a course w/id", (done)->
				student
					.post "/admin/?hmo=PUT&action=edit&type=addstudent"
					.send {
						"course":"1234"
						"id":"1001"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not add a student to a course w/username", (done)->
				student
					.post "/admin/?hmo=PUT&action=edit&type=addstudent"
					.send {
						"course":"1234"
						"username":"adminCreatedStudent"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not add a faculty to a course w/id", (done)->
				student
					.post "/admin/?hmo=PUT&action=edit&type=addfaculty"
					.send {
						"course":"1234"
						"id":"1002"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not add a faculty to a course w/username", (done)->
				student
					.post "/admin/?hmo=PUT&action=edit&type=addfaculty"
					.send {
						"course":"1234"
						"username":"adminCreatedFaculty"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not remove a student to a course w/id", (done)->
				student
					.post "/admin/?hmo=PUT&action=edit&type=rmstudent"
					.send {
						"course":"1234"
						"id":"1001"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not remove a student to a course w/username", (done)->
				student
					.post "/admin/?hmo=PUT&action=edit&type=rmstudent"
					.send {
						"course":"1234"
						"username":"adminCreatedStudent"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not remove a faculty to a course w/id", (done)->
				student
					.post "/admin/?hmo=PUT&action=edit&type=rmfaculty"
					.send {
						"course":"1234"
						"id":"1002"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not remove a faculty to a course w/username", (done)->
				student
					.post "/admin/?hmo=PUT&action=edit&type=rmfaculty"
					.send {
						"course":"1234"
						"username":"adminCreatedFaculty"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
		describe "(User: Outside)", (...)->
			it "should not return an edit course page", (done)->
				outside
					.get "/admin/?action=edit&type=course"
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not edit a course", (done)->
				outside
					.post "/admin/?hmo=PUT&action=edit&type=course"
					.send {
						"id":"1234"
						"newid":"1234"
						"title":"theNewTitle"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not add a student to a course w/id", (done)->
				outside
					.post "/admin/?hmo=PUT&action=edit&type=addstudent"
					.send {
						"course":"1234"
						"id":"1001"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not add a student to a course w/username", (done)->
				outside
					.post "/admin/?hmo=PUT&action=edit&type=addstudent"
					.send {
						"course":"1234"
						"username":"adminCreatedStudent"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not add a faculty to a course w/id", (done)->
				outside
					.post "/admin/?hmo=PUT&action=edit&type=addfaculty"
					.send {
						"course":"1234"
						"id":"1002"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not add a faculty to a course w/username", (done)->
				outside
					.post "/admin/?hmo=PUT&action=edit&type=addfaculty"
					.send {
						"course":"1234"
						"username":"adminCreatedFaculty"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not remove a student to a course w/id", (done)->
				outside
					.post "/admin/?hmo=PUT&action=edit&type=rmstudent"
					.send {
						"course":"1234"
						"id":"1001"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not remove a student to a course w/username", (done)->
				outside
					.post "/admin/?hmo=PUT&action=edit&type=rmstudent"
					.send {
						"course":"1234"
						"username":"adminCreatedStudent"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not remove a faculty to a course w/id", (done)->
				outside
					.post "/admin/?hmo=PUT&action=edit&type=rmfaculty"
					.send {
						"course":"1234"
						"id":"1002"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not remove a faculty to a course w/username", (done)->
				outside
					.post "/admin/?hmo=PUT&action=edit&type=rmfaculty"
					.send {
						"course":"1234"
						"username":"adminCreatedFaculty"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
	describe "Delete Course", (...)->
		describe "(User: Admin)", (...)->
			it.skip "should return a delete course page", (done)->
				admin
					.get "/admin/?action=delete&type=course"
					.end (err, res)->
						expect res.status .to.equal 200
						done err
			it "should delete a course", (done)->
				admin
					.post "/admin/?hmo=DELETE&action=delete&type=course"
					.send {
						"id":"1234"
					}
					.end (err, res)->
						expect res.status .to.equal 200
						done err
		describe "(User: Faculty)", (...)->
			it.skip "should not return a delete course page", (done)->
				faculty
					.get "/admin/?action=delete&type=course"
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not delete a course", (done)->
				faculty
					.post "/admin/?hmo=DELETE&action=delete&type=course"
					.send {
						"id":"1234"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
		describe "(User: Student)", (...)->
			it.skip "should not return a delete course page", (done)->
				student
					.get "/admin/?action=delete&type=course"
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not delete a course", (done)->
				student
					.post "/admin/?hmo=DELETE&action=delete&type=course"
					.send {
						"id":"1234"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
		describe "(User: Outside)", (...)->
			it.skip "should not return a delete course page", (done)->
				outside
					.get "/admin/?action=delete&type=course"
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not delete a course", (done)->
				outside
					.post "/admin/?hmo=DELETE&action=delete&type=course"
					.send {
						"id":"1234"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
	describe "Delete User", (...)->
		describe "(User: Admin)", (...)->
			it.skip "should return a delete user page", (done)->
				admin
					.get "/admin/?action=delete&type=user"
					.end (err, res)->
						expect res.status .to.equal 200
						done err
			it "should delete a student", (done)->
				admin
					.post "/admin/?hmo=DELETE&action=delete&type=user"
					.send {
						"username":"adminCreatedStudent"
						"type":"1"
					}
					.end (err, res)->
						expect res.status .to.equal 200
						done err
			it "should delete a faculty", (done)->
				admin
					.post "/admin/?hmo=DELETE&action=delete&type=user"
					.send {
						"username":"adminCreatedFaculty"
						"type":"2"
					}
					.end (err, res)->
						expect res.status .to.equal 200
						done err
			it "should delete a admin", (done)->
				admin
					.post "/admin/?hmo=DELETE&action=delete&type=user"
					.send {
						"username":"adminCreatedAdmin"
						"type":"3"
					}
					.end (err, res)->
						expect res.status .to.equal 200
						done err
		describe "(User: Faculty)", (...)->
			it.skip "should not return a delete user page", (done)->
				faculty
					.get "/admin/?action=delete&type=user"
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not delete a student", (done)->
				faculty
					.post "/admin/?hmo=DELETE&action=delete&type=user"
					.send {
						"username":"adminCreatedStudent"
						"type":"1"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not delete a faculty", (done)->
				faculty
					.post "/admin/?hmo=DELETE&action=delete&type=user"
					.send {
						"username":"adminCreatedFaculty"
						"type":"2"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not delete a admin", (done)->
				faculty
					.post "/admin/?hmo=DELETE&action=delete&type=user"
					.send {
						"username":"adminCreatedAdmin"
						"type":"3"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
		describe "(User: Student)", (...)->
			it.skip "should not return a delete user page", (done)->
				student
					.get "/admin/?action=delete&type=user"
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not delete a student", (done)->
				student
					.post "/admin/?hmo=DELETE&action=delete&type=user"
					.send {
						"username":"adminCreatedStudent"
						"type":"1"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not delete a faculty", (done)->
				student
					.post "/admin/?hmo=DELETE&action=delete&type=user"
					.send {
						"username":"adminCreatedFaculty"
						"type":"2"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not delete a admin", (done)->
				student
					.post "/admin/?hmo=DELETE&action=delete&type=user"
					.send {
						"username":"adminCreatedAdmin"
						"type":"3"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
		describe "(User: Outside)", (...)->
			it.skip "should not return a delete user page", (done)->
				outside
					.get "/admin/?action=delete&type=user"
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not delete a student", (done)->
				outside
					.post "/admin/?hmo=DELETE&action=delete&type=user"
					.send {
						"username":"adminCreatedStudent"
						"type":"1"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not delete a faculty", (done)->
				outside
					.post "/admin/?hmo=DELETE&action=delete&type=user"
					.send {
						"username":"adminCreatedFaculty"
						"type":"2"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not delete a admin", (done)->
				outside
					.post "/admin/?hmo=DELETE&action=delete&type=user"
					.send {
						"username":"adminCreatedAdmin"
						"type":"3"
					}
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			
