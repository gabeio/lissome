require! {
	'async'
	'chai' # assert lib
	'del' # delete
	'lodash'
	'supertest' # request lib
}
app = require '../lib/app'
_ = lodash
req = supertest
expect = chai.expect
assert = chai.assert
should = chai.should!
var agent, student, faculty, admin, blogpid
blogpid = []
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
				.post '/cps4601/blog/new'
				.send {
					'title':'title'
					'body':'body'
				}
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "setting up for testing edit/delete", (done)->
			err <- async.parallel [
				->
					admin
						.post '/test/getpid/cps1234'
						.send {}
						.end (err, res)->
							blogpid.0 := res.body.0._id
							done err
				->
					admin
						.post '/test/getpid/cps4601'
						.send {}
						.end (err, res)->
							blogpid.1 := res.body.0._id
							done err
			]
				# get a pid to a post here
		it "should not allow student in the course to edit or delete blog posts", (done)->
			err <- async.parallel [
				(cont)->
					student
						.post '/cps1234/blog/title?hmo=PUT'
						.send {
							'pid':blogpid.0
							'title':'anything'
							'text':'anything'
						}
						.end (err, res)->
							expect res.status .to.not.equal 200
							cont err
				(cont)->
					student
						.post '/cps1234/blog/title?hmo=DELETE'
						.send {
							'pid':blogpid.0
							'title':'anything'
							'text':'anything'
						}
						.end (err, res)->
							expect res.status .to.not.equal 200
							cont err
			]
			done err
		it "should not allow student not in the course to edit or delete blog posts", (done)->
			err <- async.parallel [
				(cont)->
					student
						.post '/cps4601/blog/title?hmo=PUT'
						.send {
							'pid':blogpid.1
							'title':'anything'
							'text':'anything'
						}
						.end (err, res)->
							expect res.status .to.not.equal 200
							cont err
				(cont)->
					student
						.post '/cps4601/blog/title?hmo=DELETE'
						.send {
							'pid':blogpid.1
							'title':'anything'
							'text':'anything'
						}
						.end (err, res)->
							expect res.status .to.not.equal 200
							cont err
			]
			done err
		it "should allow faculty in the the course to edit or delete blog posts", (done)->
			err <- async.parallel [
				(cont)->
					faculty
						.post '/cps1234/blog/title?hmo=PUT'
						.send {
							'pid':blogpid.0
							'title':'anything'
							'text':'anything'
						}
						.end (err, res)->
							expect res.status .to.equal 200
							cont err
				(cont)->
					faculty
						.post '/cps1234/blog/title?hmo=DELETE'
						.send {
							'pid':blogpid.0
							'title':'anything'
							'text':'anything'
						}
						.end (err, res)->
							expect res.status .to.equal 200
							cont err
			]
			done err
		it.skip "should not allow faculty not in the the course to edit or delete blog posts", (done)->
			err <- async.parallel [
				(cont)->
					faculty
						.post '/cps4601/blog/title?hmo=PUT'
				(cont)->
					faculty
						.post '/cps4601/blog/title?hmo=DELETE'
			]
			done err
		it.skip "should allow admin to edit or delete blog posts", (done)->
			err <- async.parallel [
				(cont)->
					admin
						.post '/cps1234/blog/title?hmo=PUT'
				(cont)->
					admin
						.post '/cps1234/blog/title?hmo=DELETE'
			]
			done err
