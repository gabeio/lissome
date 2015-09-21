require! {
	"async"
	"chai" # assert lib
	"del" # delete
	"lodash":"_"
	"mongoose"
	"supertest" # request lib
}
app = require "../lib/app"
ObjectId = mongoose.Types.ObjectId
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
		this.timeout = 0
		err <- async.parallel [
			(next)->
				err, course <- Course.findOne {
					"school":app.locals.school
					"id":"cps1234"
				}
				.exec
				courseId := course._id.toString!
				next err
			(next)->
				err, course <- Course.findOne {
					"school":app.locals.school
					"id":"cps4601"
				}
				.exec
				cps4601 := course._id.toString!
				next err
			(next)->
				student
					.post "/login"
					.send {
						"username": "student"
						"password": "password"
					}
					.end (err, res)->
						next err
			(next)->
				faculty
					.post "/login"
					.send {
						"username":"faculty"
						"password":"password"
					}
					.end (err, res)->
						next err
			(next)->
				admin
					.post "/login"
					.send {
						"username":"admin"
						"password":"password"
					}
					.end (err, res)->
						next err
		]
		done err
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
	describe "Course Settings", (...)->
		describe "(User: Admin)", (...)->
			it "should see class settings", (done)->
				admin
					.get "/c/#{courseId}/settings"
					.end (err, res)->
						expect res.status .to.equal 200
						done err
			it "should edit class settings", (done)->
				admin
					.put "/c/#{courseId}/settings"
					.send {
						"total": "100"
						"tries": "2"
						"late": "false"
						"anonymous": "false"
					}
					.end (err, res)->
						expect res.status .to.equal 302
						done err
		describe "(User: Faculty)", (...)->
			it "should see class settings", (done)->
				faculty
					.get "/c/#{courseId}/settings"
					.end (err, res)->
						expect res.status .to.equal 200
						done err
			it "should edit class settings", (done)->
				faculty
					.put "/c/#{courseId}/settings"
					.send {
						"total": "100"
						"tries": "2"
						"late": "true"
						"anonymous": "true"
					}
					.end (err, res)->
						expect res.status .to.equal 302
						done err
		describe "(User: Student)", (...)->
			it "should not see class settings", (done)->
				student
					.get "/c/#{courseId}/settings"
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not edit class settings", (done)->
				student
					.put "/c/#{courseId}/settings"
					.send {
						"total": "100"
						"tries": "2"
						"late": "false"
						"anonymous": "false"
					}
					.end (err, res)->
						expect res.status .to.equal 302
						done err
		describe "(User: Outside)", (...)->
			it "should not see class settings", (done)->
				outside
					.get "/c/#{courseId}/settings"
					.end (err, res)->
						expect res.status .to.not.equal 200
						done err
			it "should not edit class settings", (done)->
				outside
					.put "/c/#{courseId}/settings"
					.send {
						"total": "100"
						"tries": "2"
						"late": "false"
						"anonymous": "false"
					}
					.end (err, res)->
						expect res.status .to.equal 302
						done err
