require! {
	"async"
	"chai" # assert lib
	"del" # delete
	"lodash"
	"supertest" # request lib
}
app = require "../lib/app"
_ = lodash
req = supertest
expect = chai.expect
assert = chai.assert
should = chai.should!
var outside, student, faculty, admin
outside = req.agent app
student = req.agent app
faculty = req.agent app
admin = req.agent app
describe "Course" ->
	before (done)->
		student
			.post "/login"
			.send {
				"username": "student"
				"password": "password"
			}
			.end (err, res)->
				done err
	before (done)->
		faculty
			.post "/login"
			.send {
				"username":"faculty"
				"password":"password"
			}
			.end (err, res)->
				done!
	before (done)->
		admin
			.post "/login"
			.send {
				"username":"admin"
				"password":"password"
			}
			.end (err, res)->
				done!
	describe "Course Dash", (...)->
		describe "(User: Admin)", (...)->
			it "should allow access to any classes", (done)->
				admin
					.get "/cps1234"
					.end (err, res)->
						expect res.status .to.equal 200
						done err
		describe "(User: Faculty)", (...)->
			it "should allow access to their classes", (done)->
				faculty
					.get "/cps1234"
					.end (err, res)->
						expect res.status .to.equal 200
						done err
		describe "(User: Student)", (...)->
			it "should allow access to their classes", (done)->
				student
					.get "/cps1234"
					.end (err, res)->
						expect res.status .to.equal 200
						done err
			it "should not allow a student to access a class they are not in", (done)->
				student
					.get "/cps4601" # student is not in cps4601
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
		describe "(User: Outside)", (...)->
			it "should not allow any access to classes", (done)->
				outside
					.get "/cps1234"
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
	describe "Settings", (...)->
		it.skip "should allow a teacher should be able to edit their classes", (done)->
		it.skip "should allow a teacher should NOT be ablt to edit any other classes", (done)->
		it.skip "should allow an admin should be able to edit any class", (done)->
