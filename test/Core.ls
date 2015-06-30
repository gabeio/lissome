require! {
	"async"
	"chai" # assert lib
	"del" # delete
	"lodash"
	"supertest"
}
_ = lodash
req = supertest
expect = chai.expect
assert = chai.assert
should = chai.should!
var app, outside, student, faculty, admin
describe "Core" ->
	before (done)->
		app := require "../lib/app"
		app.locals.mongo.on "open", ->
			done!
	before (done)-> # setup user agents
		outside := req.agent app
		student := req.agent app
		faculty := req.agent app
		admin := req.agent app
		done!
	before (done)->
		# this is to allow app setup
		this.timeout 0
		setTimeout done, 2000
	describe "Index", (...)->
		it "should respond to a GET", (done)->
			outside
				.get "/"
				.expect 302
				.end (err, res)->
					expect res.header.location .to.equal "/login"
					done err
		it "should error to a POST", (done)->
			outside
				.post "/"
				.expect 302
				.end (err, res)->
					expect res.header.location .to.equal "/login"
					done err
		it "should error to a PUT", (done)->
			outside
				.put "/"
				.expect 302
				.end (err, res)->
					expect res.header.location .to.equal "/login"
					done err
		it "should error to a DELETE", (done)->
			outside
				.delete "/"
				.expect 302
				.end (err, res)->
					expect res.header.location .to.equal "/login"
					done err
	describe "Login", (...)->
		afterEach (complete)->
			<- async.parallel [
				(done)->
					outside
						.get "/logout"
						.end (err, res)->
							done err
				(done)->
					student
						.get "/logout"
						.end (err, res)->
							done err
				(done)->
					faculty
						.get "/logout"
						.end (err, res)->
							done err
				(done)->
					admin
						.get "/logout"
						.end (err, res)->
							done err
			]
			complete!
		it "should respond to a GET", (done)->
			outside
				.get "/login"
				.expect 200
				.end (err, res)->
					done err
		describe "(User: Admin)", (...)->
			it "should login with valid credentials", (done)->
				admin
					.post "/login"
					.send {
						"username": "Admin"
						"password": "password"
					}
					.expect 302
					.end (err, res)->
						done err
			it "should not matter how the caps the username", (done)->
				admin
					.post "/login"
					.send {
						"username": "adMIN"
						"password": "password"
					}
					.expect 302
					.end (err, res)->
						done err
			it "should fail for a good username bad password", (done)->
				admin
					.post "/login"
					.send {
						"username": "Admin"
						"password": "badpassword"
					}
					.end (err, res)->
						expect res.text .to.have.string "bad login credentials"
						done err
			it "should fail for a good username blank password", (done)->
				admin
					.post "/login"
					.send {
						"username": "Admin"
						"password": ""
					}
					.end (err, res)->
						expect res.header.location .to.be.a "undefined"
						expect res.text .to.have.string "bad login credentials"
						done err
			it "should not crash for just username defined", (done)->
				admin
					.post "/login"
					.send {
						"username":"admin"
					}
					.end (err, res)->
						# expect res.text .to.not.be ""
						expect res.text .to.have.string "bad login credentials"
						# expect res.status .to.equal 401
						done err
			it "should redirect if already logged in", (done)->
				admin
					.post "/login"
					.send {
						"username": "Admin"
						"password": "password"
					}
					.expect 302
					.end (err, res)->
						admin
							.get "/login"
							.expect 302
							.end (err, res)->
								expect res.header.location .to.equal "/"
								done err
		describe "(User: Faculty)", (...)->
			it "should login with valid credentials", (done)->
				faculty
					.post "/login"
					.send {
						"username": "Faculty"
						"password": "password"
					}
					.expect 302
					.end (err, res)->
						done err
			it "should not matter how the caps the username", (done)->
				faculty
					.post "/login"
					.send {
						"username": "facULTY"
						"password": "password"
					}
					.expect 302
					.end (err, res)->
						done err
			it "should fail for a good username bad password", (done)->
				faculty
					.post "/login"
					.send {
						"username": "Faculty"
						"password": "badpassword"
					}
					.end (err, res)->
						expect res.text .to.have.string "bad login credentials"
						done err
			it "should fail for a good username blank password", (done)->
				faculty
					.post "/login"
					.send {
						"username": "Faculty"
						"password": ""
					}
					.end (err, res)->
						expect res.header.location .to.be.a "undefined"
						expect res.text .to.have.string "bad login credentials"
						done err
			it "should not crash for just username defined", (done)->
				faculty
					.post "/login"
					.send {
						"username":"faculty"
					}
					.end (err, res)->
						expect res.text .to.have.string "bad login credentials"
						done err
			it "should redirect if already logged in", (done)->
				faculty
					.post "/login"
					.send {
						"username": "Faculty"
						"password": "password"
					}
					.expect 302
					.end (err, res)->
						faculty
							.get "/login"
							.expect 302
							.end (err, res)->
								expect res.header.location .to.equal "/"
								done err
		describe "(User: Student)", (...)->
			it "should login with valid credentials", (done)->
				student
					.post "/login"
					.send {
						"username": "Student"
						"password": "password"
					}
					.expect 302
					.end (err, res)->
						done err
			it "should not matter how the caps the username", (done)->
				student
					.post "/login"
					.send {
						"username": "stuDENT"
						"password": "password"
					}
					.expect 302
					.end (err, res)->
						done err
			it "should fail for a good username bad password", (done)->
				student
					.post "/login"
					.send {
						"username": "Student"
						"password": "badpassword"
					}
					.end (err, res)->
						expect res.text .to.have.string "bad login credentials"
						done err
			it "should fail for a good username blank password", (done)->
				student
					.post "/login"
					.send {
						"username": "Student"
						"password": ""
					}
					.end (err, res)->
						expect res.header.location .to.be.a "undefined"
						expect res.text .to.have.string "bad login credentials"
						done err
			it "should not crash for just username defined", (done)->
				student
					.post "/login"
					.send {
						"username":"student"
					}
					.end (err, res)->
						expect res.text .to.have.string "bad login credentials"
						done err
			it "should redirect if already logged in", (done)->
				student
					.post "/login"
					.send {
						"username": "Student"
						"password": "password"
					}
					.expect 302
					.end (err, res)->
						student
							.get "/login"
							.expect 302
							.end (err, res)->
								expect res.header.location .to.equal "/"
								done err
		it "should fail for a blank user", (done)->
			student
				.post "/login"
				.send {
					"username": "student"
					"password": ""
				}
				.end (err, res)->
					expect res.text .to.have.string "bad login credentials"
					expect res.headers.location .to.be.an "undefined"
					done err
		it "should fail for a bad username", (done)->
			admin
				.post "/login"
				.send {
					"username": "who?"
					"password": "bad"
				}
				.end (err, res)->
					expect res.text .to.have.string "username not found"
					expect res.headers.location .to.be.an "undefined"
					done err
	describe "Dashboard", (...)->
		before (done)->
			student
				.post "/login"
				.send {
					"username": "Student"
					"password": "password"
				}
				.end (err, res)->
					done err
		before (done)->
			faculty
				.post "/login"
				.send {
					"username": "Faculty"
					"password": "password"
				}
				.end (err, res)->
					done err
		before (done)->
			admin
				.post "/login"
				.send {
					"username": "Admin"
					"password": "password"
				}
				.end (err, res)->
					done err
		describe "(User: Admin)", (...)->
			it "should display your courses", (done)->
				admin
					.get "/"
					.end (err, res)->
						expect res.status .to.equal 200
						expect res.text .to.have.string "Courses"
						done err
		describe "(User: Faculty)", (...)->
			it "should display your courses", (done)->
				faculty
					.get "/"
					.end (err, res)->
						expect res.status .to.equal 200
						expect res.text .to.have.string "Your Courses"
						done err
		describe "(User: Student)", (...)->
			it "should display your courses", (done)->
				student
					.get "/"
					.end (err, res)->
						expect res.status .to.equal 200
						expect res.text .to.have.string "Your Courses"
						done err
		describe "(User: Outside)", (...)->
			it "should display your courses", (done)->
				outside
					.get "/"
					.end (err, res)->
						expect res.status .to.not.equal 200
						expect res.text .to.not.have.string "Your Courses"
						done err
