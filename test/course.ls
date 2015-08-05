require! {
	"async"
	"chai" # assert lib
	"del" # delete
	"lodash"
	"mongoose"
	"supertest" # request lib
}
app = require "../lib/app"
ObjectId = mongoose.Types.ObjectId
_ = lodash
Course = mongoose.models.Course
req = supertest
expect = chai.expect
assert = chai.assert
should = chai.should!
var outside, student, faculty, admin, courseId, cps4601
outside = req.agent app
student = req.agent app
faculty = req.agent app
admin = req.agent app
describe "Course" ->
	before (done)->
		err, course <- Course.findOne {
			"school":app.locals.school
			"id":"cps1234"
		}
		.exec
		courseId := course._id.toString!
		done err
	before (done)->
		err, course <- Course.findOne {
			"school":app.locals.school
			"id":"cps4601"
		}
		.exec
		cps4601 := course._id.toString!
		done err
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
					.get "/c/#{courseId}"
					.end (err, res)->
						expect res.status .to.equal 200
						done err
		describe "(User: Faculty)", (...)->
			it "should allow access to their classes", (done)->
				faculty
					.get "/c/#{courseId}"
					.end (err, res)->
						expect res.status .to.equal 200
						done err
		describe "(User: Student)", (...)->
			it "should allow access to their classes", (done)->
				student
					.get "/c/#{courseId}"
					.end (err, res)->
						expect res.status .to.equal 200
						done err
			it "should not allow a student to access a class they are not in", (done)->
				student
					.get "/c/#{cps4601}" # student is not in cps4601
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
		describe "(User: Outside)", (...)->
			it "should not allow any access to classes", (done)->
				outside
					.get "/c/#{courseId}"
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
	describe "Course Roster", (...)->
		describe "(User: Admin)", (...)->
			it "should see class roster", (done)->
				admin
					.get "/c/#{courseId}/roster"
					.end (err, res)->
						expect res.status .to.equal 200
						done err
		describe "(User: Faculty)", (...)->
			it "should see class roster", (done)->
				faculty
					.get "/c/#{courseId}/roster"
					.end (err, res)->
						expect res.status .to.equal 200
						done err
		describe "(User: Student)", (...)->
			it "should see class roster", (done)->
				student
					.get "/c/#{courseId}/roster"
					.end (err, res)->
						expect res.status .to.equal 200
						done err
			it "should not allow a student to access a class they are not in", (done)->
				student
					.get "/c/#{cps4601}/roster" # student is not in cps4601
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
		describe "(User: Outside)", (...)->
			it "should not allow any access to classes", (done)->
				outside
					.get "/c/#{courseId}/roster"
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
	describe "Settings", (...)->
		it.skip "should allow a teacher should be able to edit their classes", (done)->
		it.skip "should allow a teacher should NOT be ablt to edit any other classes", (done)->
		it.skip "should allow an admin should be able to edit any class", (done)->
