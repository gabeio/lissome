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
var app, agent, student, faculty, admin
describe "Core" ->
	before (done)->
		app := require "../lib/app"
		app.locals.mongo.on "open", ->
			done!
	before (done)-> # setup user agents
		agent := req.agent app
		student := req.agent app
		faculty := req.agent app
		admin := req.agent app
		done!
	before (done)->
		# this is to allow app setup
		this.timeout 0
		setTimeout done, 1000
	describe "Index", (...)->
		it "should respond to a GET", (done)->
			agent
				.get "/"
				.end (err, res)->
					expect res.header.location .to.equal "/login"
					expect res.status .to.equal 302
					done err
		it "should error to a POST", (done)->
			agent
				.post "/"
				.end (err, res)->
					expect res.header.location .to.equal "/login"
					expect res.status .to.not.equal 200
					done err
		it "should error to a PUT", (done)->
			agent
				.put "/"
				.end (err, res)->
					expect res.header.location .to.equal "/login"
					expect res.status .to.not.equal 200
					done err
		it "should error to a DELETE", (done)->
			agent
				.delete "/"
				.end (err, res)->
					expect res.header.location .to.equal "/login"
					expect res.status .to.not.equal 200
					done err
	describe "Login", (...)->
		afterEach (complete)->
			<- async.parallel [
				(done)->
					agent
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
			agent
				.get "/login"
				.end (err, res)->
					expect res.status .to.equal 200
					# expect res.text .to.
					done err
		it "should login with valid student credentials", (done)->
			student
				.post "/login"
				.send {
					"username": "Student"
					"password": "password"
				}
				.end (err, res)->
					expect res.status .to.equal 302
					done err
		it "should login with valid faculty credentials", (done)->
			faculty
				.post "/login"
				.send {
					"username": "Faculty"
					"password": "password"
				}
				.end (err, res)->
					expect res.status .to.equal 302
					done err
		it "should login with valid admin credentials", (done)->
			admin
				.post "/login"
				.send {
					"username": "Admin"
					"password": "password"
				}
				.end (err, res)->
					expect res.status .to.equal 302
					done err
		it "should not matter how the student caps the username", (done)->
			student
				.post "/login"
				.send {
					"username": "stuDENT"
					"password": "password"
				}
				.end (err, res)->
					expect res.status .to.equal 302
					done err
		it "should not matter how the faculty caps the username", (done)->
			faculty
				.post "/login"
				.send {
					"username": "facULTY"
					"password": "password"
				}
				.end (err, res)->
					expect res.status .to.equal 302
					done err
		it "should not matter how the admin caps the username", (done)->
			admin
				.post "/login"
				.send {
					"username": "adMIN"
					"password": "password"
				}
				.end (err, res)->
					expect res.status .to.equal 302
					done err
		it "should ignore put/delete to login as outside", (done)->
			err <- async.parallel [
				(cont)->
					agent
						.put "/login"
						.send {
							"username":"gibberish"
							"password":"idk"
							"anything":"else"
						}
						.end (err, res)->
							expect res.status .to.not.equal 200
							cont err
				(cont)->
					agent
						.delete "/login"
						.send {
							"username":"gibberish"
							"password":"idk"
							"anything":"else"
						}
						.end (err, res)->
							expect res.status .to.not.equal 200
							cont err
			]
			done err
		it "should ignore put/delete to login as student", (done)->
			student
				.post "/login"
				.send {
					"username": "stuDENT"
					"password": "password"
				}
				.end (err, res)->
					err <- async.parallel [
						(cont)->
							student
								.put "/login"
								.send {
									"username":"gibberish"
									"password":"idk"
									"anything":"else"
								}
								.end (err, res)->
									expect res.status .to.not.equal 200
									cont err
						(cont)->
							student
								.delete "/login"
								.send {
									"username":"gibberish"
									"password":"idk"
									"anything":"else"
								}
								.end (err, res)->
									expect res.status .to.not.equal 200
									cont err
					]
					done err
		it "should ignore put/delete to login as faculty", (done)->
			faculty
				.post "/login"
				.send {
					"username": "Faculty"
					"password": "password"
				}
				.end (err, res)->
					err <- async.parallel [
						(cont)->
							faculty
								.put "/login"
								.send {
									"username":"gibberish"
									"password":"idk"
									"anything":"else"
								}
								.end (err, res)->
									expect res.status .to.not.equal 200
									cont err
						(cont)->
							faculty
								.delete "/login"
								.send {
									"username":"gibberish"
									"password":"idk"
									"anything":"else"
								}
								.end (err, res)->
									expect res.status .to.not.equal 200
									cont err
					]
					done err
		it "should ignore put/delete to login as admin", (done)->
			admin
				.post "/login"
				.send {
					"username": "Admin"
					"password": "password"
				}
				.end (err, res)->
					err <- async.parallel [
						(cont)->
							admin
								.put "/login"
								.send {
									"username":"gibberish"
									"password":"idk"
									"anything":"else"
								}
								.end (err, res)->
									expect res.status .to.not.equal 200
									cont err
						(cont)->
							admin
								.delete "/login"
								.send {
									"username":"gibberish"
									"password":"idk"
									"anything":"else"
								}
								.end (err, res)->
									expect res.status .to.not.equal 200
									cont err
					]
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
		it "should fail for a good student username bad password", (done)->
			student
				.post "/login"
				.send {
					"username": "Student"
					"password": "badpassword"
				}
				.end (err, res)->
					expect res.text .to.have.string "bad login credentials"
					done err
		it "should fail for a good faculty username bad password", (done)->
			faculty
				.post "/login"
				.send {
					"username": "Faculty"
					"password": "badpassword"
				}
				.end (err, res)->
					expect res.text .to.have.string "bad login credentials"
					done err
		it "should fail for a good admin username bad password", (done)->
			admin
				.post "/login"
				.send {
					"username": "Admin"
					"password": "badpassword"
				}
				.end (err, res)->
					expect res.text .to.have.string "bad login credentials"
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
		it "should fail for a good student username blank password", (done)->
			student
				.post "/login"
				.send {
					"username": "Student"
					"password": "bad"
				}
				.end (err, res)->
					expect res.header.location .to.be.a "undefined"
					expect res.text .to.have.string "bad login credentials"
					done err
		it "should fail for a good faculty username blank password", (done)->
			faculty
				.post "/login"
				.send {
					"username": "Faculty"
					"password": "bad"
				}
				.end (err, res)->
					expect res.header.location .to.be.a "undefined"
					expect res.text .to.have.string "bad login credentials"
					done err
		it "should fail for a good admin username blank password", (done)->
			admin
				.post "/login"
				.send {
					"username": "Admin"
					"password": "bad"
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
					# expect res.text .to.not.be ""
					expect res.text .to.have.string "bad login credentials"
					# expect res.status .to.equal 401
					done err
		it "should redirect if already logged in (student)", (done)->
			student
				.post "/login"
				.send {
					"username": "Student"
					"password": "password"
				}
				.end (err, res)->
					expect res.status .to.equal 302
					student
						.get "/login"
						.end (err, res)->
							expect res.header.location .to.equal "/"
							done err
		it "should redirect if already logged in (faculty)", (done)->
			faculty
				.post "/login"
				.send {
					"username": "Faculty"
					"password": "password"
				}
				.end (err, res)->
					expect res.status .to.equal 302
					faculty
						.get "/login"
						.end (err, res)->
							expect res.header.location .to.equal "/"
							done err
		it "should redirect if already logged in (admin)", (done)->
			admin
				.post "/login"
				.send {
					"username": "Admin"
					"password": "password"
				}
				.end (err, res)->
					expect res.status .to.equal 302
					admin
						.get "/login"
						.end (err, res)->
							expect res.header.location .to.equal "/"
							done err
	describe "Dashboard", (...)->
		before (done)->
			err <- async.parallel [
				(cont)->
					student
						.post "/login"
						.send {
							"username": "Student"
							"password": "password"
						}
						.end (err, res)->
							expect res.status .to.equal 302
							cont err
				(cont)->
					faculty
						.post "/login"
						.send {
							"username": "Faculty"
							"password": "password"
						}
						.end (err, res)->
							expect res.status .to.equal 302
							cont err
				(cont)->
					admin
						.post "/login"
						.send {
							"username": "Admin"
							"password": "password"
						}
						.end (err, res)->
							expect res.status .to.equal 302
							cont err
			]
			done err
		it "should display your courses", (done)->
			err <- async.parallel [
				(cont)->
					student
						.get "/"
						.end (err, res)->
							expect res.status .to.equal 200
							expect res.text .to.have.string "Your Courses"
							cont err
				(cont)->
					faculty
						.get "/"
						.end (err, res)->
							expect res.status .to.equal 200
							expect res.text .to.have.string "Your Courses"
							cont err
				(cont)->
					admin
						.get "/"
						.end (err, res)->
							expect res.status .to.equal 200
							expect res.text .to.have.string "Your Courses"
							cont err
			]
			done err
	# describe "Dashboard", (...)->
	# 	it.skip "should show any changes to any classes a student presently enrolled in"	
