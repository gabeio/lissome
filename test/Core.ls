require! {
	"async"
	"chai" # assert lib
	"del" # delete
	"lodash":"_"
	"supertest"
	"passcode"
}
req = supertest
expect = chai.expect
assert = chai.assert
should = chai.should!
var app, outside, student, faculty, admin
describe "Core" ->
	before (done)->
		this.timeout = 0 # allow setup for as long as needed
		app := require "../lib/app"
		outside := req.agent app
		student := req.agent app
		faculty := req.agent app
		admin := req.agent app
		err <- async.parallel [
			(wait)->
				app.locals.mongoose.connections.0.once "open" (err)->
					wait err
			(wait)->
				app.locals.redis.once "ready" (err)->
					wait err
		]
		done err
	describe "Index", (...)->
		it "should respond to a GET", (done)->
			outside
				.get "/"
				.expect 302
				.end (err, res)->
					expect res.headers.location .to.equal "/login"
					done err
		it "should error to a POST", (done)->
			outside
				.post "/"
				.expect 302
				.end (err, res)->
					expect res.headers.location .to.equal "/login"
					done err
		it "should error to a PUT", (done)->
			outside
				.put "/"
				.expect 302
				.end (err, res)->
					expect res.headers.location .to.equal "/login"
					done err
		it "should error to a DELETE", (done)->
			outside
				.delete "/"
				.expect 302
				.end (err, res)->
					expect res.headers.location .to.equal "/login"
					done err
	describe "Login", (...)->
		afterEach (complete)->
			err <- async.parallel [
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
			complete err
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
						expect res.headers.location .to.equal "/bounce?to=/"
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
						expect res.headers.location .to.equal "/bounce?to=/"
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
						expect res.headers.location .to.be.a "undefined"
						expect res.text .to.have.string "bad login credentials"
						done err
			it "should not crash for just username defined", (done)->
				admin
					.post "/login"
					.send {
						"username":"admin"
					}
					.end (err, res)->
						expect res.text .to.have.string "bad login credentials"
						done err
			it "should redirect if no otp", (done)->
				err <- async.waterfall [
					(next)->
						admin
							.post "/login"
							.send {
								"username": "admin"
								"password": "password"
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/"
								next err
					(next)->
						admin
							.get "/otp"
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/"
								next err
				]
				done err
			it "should redirect if already logged in", (done)->
				err <- async.waterfall [
					(next)->
						admin
							.post "/login"
							.send {
								"username": "Admin"
								"password": "password"
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/"
								next err
					(next)->
						admin
							.get "/login"
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/"
								next err
				]
				done err
			it "should tell them to enable cookies", (done)->
				admin
					.get "/bounce?to=/"
					.expect 200
					.end (err, res)->
						expect res.text .to.have.string "enable cookies"
						done err
			it "should succeed for a good totp", (done)->
				err <- async.waterfall [
					(next)->
						admin
							.post "/login"
							.send {
								"username": "zadmin"
								"password": "password"
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/otp"
								next err
					(next)->
						admin
							.post "/otp"
							.send {
								"token": passcode.totp { secret: "4JZPEQXTGFNCR76H", encoding: "base32" }
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/"
								next err
				]
				done err
			it "should fail for a bad totp", (done)->
				err <- async.waterfall [
					(next)->
						admin
							.post "/login"
							.send {
								"username": "zadmin"
								"password": "password"
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/otp"
								next err
					(next)->
						admin
							.post "/otp"
							.send {
								"token":"000000"
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/login"
								next err
				]
				done err
			it "should not take a blank totp", (done)->
				err <- async.waterfall [
					(next)->
						admin
							.post "/login"
							.send {
								"username": "zadmin"
								"password": "password"
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/otp"
								next err
					(next)->
						admin
							.post "/otp"
							.send {
								"otp":""
							}
							.expect 400
							.end (err, res)->
								expect res.headers.location .to.be.an "undefined"
								next err
				]
				done err
			it "should redirect to totp", (done)->
				err <- async.waterfall [
					(next)->
						admin
							.post "/login"
							.send {
								"username": "zadmin"
								"password": "password"
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/otp"
								next err
					(next)->
						admin
							.get "/login"
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/otp"
								next err
				]
				done err
			it "should succeed for a good pin", (done)->
				this.timeout = 3000
				err <- async.waterfall [
					(next)->
						admin
							.post "/login"
							.send {
								"username": "yadmin"
								"password": "password"
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/pin"
								next err
					(next)->
						admin
							.get "/test/getpin"
							.end (err, res)->
								next err, res.text
					(pin,next)->
						admin
							.post "/pin"
							.send {
								"pin": pin
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/"
								next err
				]
				done err
			it "should not take a blank pin", (done)->
				err <- async.waterfall [
					(next)->
						admin
							.post "/login"
							.send {
								"username": "yadmin"
								"password": "password"
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/pin"
								next err
					(next)->
						admin
							.post "/pin"
							.send {
								"pin": ""
							}
							.expect 400
							.end (err, res)->
								next err
				]
				done err
			it "should fail for a bad pin", (done)->
				this.timeout = 3000
				err <- async.waterfall [
					(next)->
						admin
							.post "/login"
							.send {
								"username": "xadmin"
								"password": "password"
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/pin"
								next err
					(next)->
						admin
							.get "/test/getpin"
							.end (err, res)->
								next err, parseInt(res.body)
					(pin,next)->
						pin+=10
						admin
							.post "/pin"
							.send {
								"pin": pin.toString!
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/login"
								next err
				]
				done err
			it "should redirect if no pin", (done)->
				err <- async.waterfall [
					(next)->
						admin
							.post "/login"
							.send {
								"username": "admin"
								"password": "password"
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/"
								next err
					(next)->
						admin
							.get "/pin"
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/"
								next err
				]
				done err
			it "should redirect to pin", (done)->
				err <- async.waterfall [
					(next)->
						admin
							.post "/login"
							.send {
								"username": "xadmin"
								"password": "password"
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/pin"
								next err
					(next)->
						admin
							.get "/login"
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/pin"
								next err
				]
				done err
			it "should be locked out", (done)->
				err <- async.waterfall [
					(next)->
						admin
							.post "/login"
							.send {
								"username": "badmin"
								"password": "password"
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/pin"
								next err
					(next)->
						admin
							.get "/pin"
							.end (err, res)->
								next err
				]
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
						expect res.headers.location .to.equal "/bounce?to=/"
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
						expect res.headers.location .to.equal "/bounce?to=/"
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
						expect res.headers.location .to.be.a "undefined"
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
			it "should redirect if no otp", (done)->
				err <- async.waterfall [
					(next)->
						faculty
							.post "/login"
							.send {
								"username": "faculty"
								"password": "password"
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/"
								next err
					(next)->
						faculty
							.get "/otp"
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/"
								next err
				]
				done err
			it "should redirect if already logged in", (done)->
				err <- async.waterfall [
					(next)->
						faculty
							.post "/login"
							.send {
								"username": "Faculty"
								"password": "password"
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/"
								next err
					(next)->
						faculty
							.get "/login"
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/"
								next err
				]
				done err
			it "should tell them to enable cookies", (done)->
				faculty
					.get "/bounce?to=/"
					.expect 200
					.end (err, res)->
						expect res.text .to.have.string "enable cookies"
						done err
			it "should succeed for a good totp", (done)->
				err <- async.waterfall [
					(next)->
						faculty
							.post "/login"
							.send {
								"username": "zfaculty"
								"password": "password"
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/otp"
								next err
					(next)->
						faculty
							.post "/otp"
							.send {
								"token": passcode.totp { secret: "4JZPEQXTGFNCR76H", encoding: "base32" }
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/"
								next err
				]
				done err
			it "should fail for a bad totp", (done)->
				err <- async.waterfall [
					(next)->
						faculty
							.post "/login"
							.send {
								"username": "zfaculty"
								"password": "password"
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/otp"
								next err
					(next)->
						faculty
							.post "/otp"
							.send {
								"token":"000000"
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/login"
								next err
				]
				done err
			it "should not take a blank totp", (done)->
				err <- async.waterfall [
					(next)->
						faculty
							.post "/login"
							.send {
								"username": "zfaculty"
								"password": "password"
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/otp"
								next err
					(next)->
						faculty
							.post "/otp"
							.send {
								"otp":""
							}
							.expect 400
							.end (err, res)->
								expect res.headers.location .to.be.an "undefined"
								next err
				]
				done err
			it "should succeed for a good pin", (done)->
				this.timeout = 3000
				err <- async.waterfall [
					(next)->
						faculty
							.post "/login"
							.send {
								"username": "yfaculty"
								"password": "password"
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/pin"
								next err
					(next)->
						faculty
							.get "/test/getpin"
							.end (err, res)->
								next err, res.text
					(pin,next)->
						faculty
							.post "/pin"
							.send {
								"pin": pin
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/"
								next err
				]
				done err
			it "should not take a blank pin", (done)->
				err <- async.waterfall [
					(next)->
						faculty
							.post "/login"
							.send {
								"username": "yfaculty"
								"password": "password"
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/pin"
								next err
					(next)->
						faculty
							.post "/pin"
							.send {
								"pin": ""
							}
							.expect 400
							.end (err, res)->
								next err
				]
				done err
			it "should fail for a bad pin", (done)->
				this.timeout = 3000
				err <- async.waterfall [
					(next)->
						faculty
							.post "/login"
							.send {
								"username": "xfaculty"
								"password": "password"
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/pin"
								next err
					(next)->
						faculty
							.get "/test/getpin"
							.end (err, res)->
								next err, parseInt(res.body)
					(pin,next)->
						pin+=10
						faculty
							.post "/pin"
							.send {
								"pin": pin.toString!
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/login"
								next err
				]
				done err
			it "should redirect if no pin", (done)->
				err <- async.waterfall [
					(next)->
						faculty
							.post "/login"
							.send {
								"username": "faculty"
								"password": "password"
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/"
								next err
					(next)->
						faculty
							.get "/pin"
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/"
								next err
				]
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
						expect res.headers.location .to.equal "/bounce?to=/"
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
						expect res.headers.location .to.equal "/bounce?to=/"
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
						expect res.headers.location .to.be.a "undefined"
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
			it "should redirect if no otp", (done)->
				err <- async.waterfall [
					(next)->
						student
							.post "/login"
							.send {
								"username": "student"
								"password": "password"
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/"
								next err
					(next)->
						student
							.get "/otp"
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/"
								next err
				]
				done err
			it "should redirect if already logged in", (done)->
				err <- async.waterfall [
					(next)->
						student
							.post "/login"
							.send {
								"username": "Student"
								"password": "password"
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/"
								next err
					(next)->
						student
							.get "/login"
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/"
								next err
				]
				done err
			it "should tell them to enable cookies", (done)->
				student
					.get "/bounce?to=/"
					.expect 200
					.end (err, res)->
						expect res.text .to.have.string "enable cookies"
						done err
			it "should succeed for a good totp", (done)->
				err <- async.waterfall [
					(next)->
						student
							.post "/login"
							.send {
								"username": "zstudent"
								"password": "password"
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/otp"
								next err
					(next)->
						student
							.post "/otp"
							.send {
								"token": passcode.totp { secret: "4JZPEQXTGFNCR76H", encoding: "base32" }
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/"
								next err
				]
				done err
			it "should fail for a bad totp", (done)->
				err <- async.waterfall [
					(next)->
						student
							.post "/login"
							.send {
								"username": "zstudent"
								"password": "password"
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/otp"
								next err
					(next)->
						student
							.post "/otp"
							.send {
								"token":"000000"
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/login"
								next err
				]
				done err
			it "should not take a blank totp", (done)->
				err <- async.waterfall [
					(next)->
						student
							.post "/login"
							.send {
								"username": "zstudent"
								"password": "password"
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/otp"
								next err
					(next)->
						student
							.post "/otp"
							.send {
								"otp":""
							}
							.expect 400
							.end (err, res)->
								expect res.headers.location .to.be.an "undefined"
								next err
				]
				done err
			it "should succeed for a good pin", (done)->
				this.timeout = 3000
				err <- async.waterfall [
					(next)->
						student
							.post "/login"
							.send {
								"username": "ystudent"
								"password": "password"
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/pin"
								next err
					(next)->
						student
							.get "/test/getpin"
							.end (err, res)->
								next err, res.text
					(pin,next)->
						student
							.post "/pin"
							.send {
								"pin": pin
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/"
								next err
				]
				done err
			it "should not take a blank pin", (done)->
				err <- async.waterfall [
					(next)->
						student
							.post "/login"
							.send {
								"username": "ystudent"
								"password": "password"
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/pin"
								next err
					(next)->
						student
							.post "/pin"
							.send {
								"pin": ""
							}
							.expect 400
							.end (err, res)->
								next err
				]
				done err
			it "should fail for a bad pin", (done)->
				this.timeout = 3000
				err <- async.waterfall [
					(next)->
						student
							.post "/login"
							.send {
								"username": "xstudent"
								"password": "password"
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/pin"
								next err
					(next)->
						student
							.get "/test/getpin"
							.end (err, res)->
								next err, parseInt(res.body)
					(pin,next)->
						pin+=10
						student
							.post "/pin"
							.send {
								"pin": pin.toString!
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/login"
								next err
				]
				done err
			it "should redirect if no pin", (done)->
				err <- async.waterfall [
					(next)->
						student
							.post "/login"
							.send {
								"username": "student"
								"password": "password"
							}
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/bounce?to=/"
								next err
					(next)->
						student
							.get "/pin"
							.expect 302
							.end (err, res)->
								expect res.headers.location .to.equal "/"
								next err
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
		it "should fail for a bad username", (done)->
			admin
				.post "/login"
				.send {
					"username": "who?"
					"password": "bad"
				}
				.end (err, res)->
					expect res.text .to.have.string "user not found"
					expect res.headers.location .to.be.an "undefined"
					done err
	describe "Bounce", (...)->
		it "should redirect to location given by query", (done)->
			err <- async.waterfall [
				(next)->
					admin
						.post "/login"
						.send {
							"username": "Admin"
							"password": "password"
						}
						.expect 302
						.end (err, res)->
							expect res.headers.location .to.equal "/bounce?to=/"
							next err, res.headers.location
				(location, next)->
					admin
						.get location
						.expect 302
						.end (err, res)->
							expect res.headers.location .to.equal "/"
							next err
			]
			done err
	describe "Dashboard", (...)->
		before (done)->
			this.timeout = 0
			err <- async.parallel [
				(next)->
					student
						.post "/login"
						.send {
							"username": "Student"
							"password": "password"
						}
						.expect 302
						.end (err, res)->
							next err
				(next)->
					faculty
						.post "/login"
						.send {
							"username": "Faculty"
							"password": "password"
						}
						.expect 302
						.end (err, res)->
							next err
				(next)->
					admin
						.post "/login"
						.send {
							"username": "Admin"
							"password": "password"
						}
						.expect 302
						.end (err, res)->
							next err
			]
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
						expect res.text .to.have.string "Courses"
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
