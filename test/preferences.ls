require! {
	"async"
	"chai" # assert lib
	"del" # delete
	"lodash":"_"
	"moment"
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
var agent, student, faculty, admin, courseId, blogpid
assignid = []
outside = req.agent app
student = req.agent app
faculty = req.agent app
admin = req.agent app
describe "Preferences" ->
	before (done)->
		this.timeout = 0
		err <- async.parallel [
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
	describe "(User: Admin)", (...)->
		it "Index Template", (done)->
			admin
				.get "/preferences"
				.end (err, res)->
					expect res.status .to.equal 200
					done err
	describe "(User: Faculty)", (...)->
		it "Index Template", (done)->
			faculty
				.get "/preferences"
				.end (err, res)->
					expect res.status .to.equal 200
					done err
	describe "(User: Student)", (...)->
		it "Index Template", (done)->
			student
				.get "/preferences"
				.end (err, res)->
					expect res.status .to.equal 200
					done err
	# describe "Other", (...)->
	# 	...
