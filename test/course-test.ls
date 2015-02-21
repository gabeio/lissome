require! {
	'chai' # assert lib
	'supertest' # request lib
	'del' # delete
	'async'
}
app = require '../lib/app'
req = supertest
expect = chai.expect
assert = chai.assert
should = chai.should!
var agent, student, faculty, admin
agent = req.agent app
student = req.agent app
faculty = req.agent app
admin = req.agent app
describe "Course" ->
	describe "Login", (...)->
		it "signing into student", (done)->
			student
				.post '/login'
				.send {
					'username': 'student'
					'password': 'password'
				}
				.end (err, res)->
					expect res.status .to.equal 302
					done err
		it "signing into faculty", (done)->
			faculty
				.post '/login'
				.send {
					'username':'faculty'
					'password':'password'
				}
				.end (err, res)->
					expect res.status .to.equal 302
					done!
		it "signing into admin", (done)->
			admin
				.post '/login'
				.send {
					'username':'admin'
					'password':'password'
				}
				.end (err, res)->
					expect res.status .to.equal 302
					done!
	describe "Course Dash", (...)->
		# before (done)->
		it "should allow a student to access their classes", (done)->
			student
				.get '/cps1234'
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should not allow a student should NOT be able to access any other classes", (done)->
			student
				.get '/cps4601' # student is not in cps4601
				.end (err, res)->
					expect res.status .to.not.equal 200
					done err
	describe "Course Settings", (...)->
		it "should allow a teacher should be able to edit their classes"
		it "should allow a teacher should NOT be ablt to edit any other classes"
		it "should allow an admin should be able to edit any class"
	describe "Course Blog", (...)->
		it "should be visible to student in the course", (done)->
			student
				.get '/cps1234/blog'
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should not be visible to student not in the course", (done)->
			student
				.get '/cps4601/blog'
				.end (err, res)->
					expect res.status .to.not.equal 200
					done err
		it "should not allow students in the course to create new posts", (done)->
			student
				.post '/cps1234/blog/new'
				.send {
					'title':'title'
					'body':'body'
				}
				.end (err, res)->
					expect res.status .to.not.equal 200
					done err
		it "should not allow students not in the course to create new posts", (done)->
			student
				.post '/cps4601/blog/new'
				.send {
					'title':'title'
					'body':'body'
				}
				.end (err, res)->
					expect res.status .to.not.equal 200
					done err
		it "should allow faculty in the course to create new posts", (done)->
			faculty
				.post '/cps1234/blog/new'
				.send {
					'title':'title'
					'body':'body'
				}
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should not allow faculty not in the course to create new posts", (done)->
			faculty
				.post '/cps4601/blog/new'
				.send {
					'title':'title'
					'body':'body'
				}
				.end (err, res)->
					expect res.status .to.not.equal 200
					done err
		it "should allow admin to create new posts", (done)->
			admin
				.post '/cps1234/blog/new'
				.send {
					'title':'title'
					'body':'body'
				}
				.end (err, res)->
					expect res.status .to.equal 200
					done err
