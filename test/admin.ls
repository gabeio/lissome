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
describe "Admin" ->
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
	describe "Admin", (...)->
		it "should allow an admin to create a student", (done)->
			admin
				.post "/admin/?action=create&type=user"
				.send {
					"id":"134159"
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
					"id":"311459"
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
					"id":"314199"
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
					"id":"12345"
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
					"id":"314199"
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
					"id":"3141995"
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
					"id":"300"
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
					"id":"301"
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
