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
	describe "Settings", (...)->
		it "should allow a teacher should be able to edit their classes"
		it "should allow a teacher should NOT be ablt to edit any other classes"
		it "should allow an admin should be able to edit any class"
	describe "Blog", (...)->
		beforeEach (done)->
			admin
				.post '/test/postblog'
				.send {
					'course':'cps1234'
					'title':'title'
					'text':'text'
				}
				.end (err, res)->
					expect res.status .to.equal 200
					done err
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
				.post '/cps1234/blog?action=new'
				.send {
					'title':'title'
					'text':'student'
				}
				.end (err, res)->
					expect res.status .to.not.equal 200
					done err
		it "should not allow students not in the course to create new posts", (done)->
			err <- async.parallel [
				(cont)->
					student
						.post '/cps4601/blog?action=new'
						.send {
							'title':'title'
							'text':'student'
						}
						.end (err, res)->
							expect res.status .to.not.equal 200
							cont err
				(cont)->
					student
						.get '/cps4601/blog?action=new'
						.end (err, res)->
							expect res.status .to.not.equal 200
							cont err
				(cont)->
					student
						.get '/cps4601/blog?action=edit'
						.end (err, res)->
							expect res.status .to.not.equal 200
							cont err
				(cont)->
					student
						.get '/cps4601/blog?action=delete'
						.end (err, res)->
							expect res.status .to.not.equal 200
							cont err
			]
			done err
		it "should allow faculty in the course to create new posts", (done)->
			err <- async.parallel [
				(cont)->
					faculty
						.post '/cps1234/blog?action=new'
						.send {
							'title':'title'
							'text':'faculty'
						}
						.end (err, res)->
							expect res.status .to.equal 200
							cont err
				(cont)->
					faculty
						.get '/cps1234/blog?action=new'
						.end (err, res)->
							expect res.status .to.equal 200
							cont err
			]
			done err
		it "should not allow faculty not in the course to create new posts", (done)->
			err <- async.parallel [
				(cont)->
					faculty
						.post '/cps4601/blog?action=new'
						.send {
							'title':'title'
							'text':'bad faculty'
						}
						.end (err, res)->
							expect res.status .to.not.equal 200
							cont err
				(cont)->
					faculty
						.get '/cps4601/blog?action=new'
						.end (err, res)->
							expect res.status .to.not.equal 200
							cont err
			]
			done err
		it "should allow admin to create new posts in any course", (done)->
			err <- async.parallel [
				(cont)->
					admin
						.post '/cps4601/blog?action=new'
						.send {
							'title':'title'
							'text':'admin'
						}
						.end (err, res)->
							expect res.status .to.equal 200
							cont err
				(cont)->
					admin
						.get '/cps4601/blog?action=new'
						.end (err, res)->
							expect res.status .to.equal 200
							cont err
				(cont)->
					admin
						.post '/cps1234/blog?action=new'
						.send {
							'title':'title'
							'text':'admin'
						}
						.end (err, res)->
							expect res.status .to.equal 200
							cont err
				(cont)->
					admin
						.get '/cps1234/blog?action=new'
						.end (err, res)->
							expect res.status .to.equal 200
							cont err
			]
			done err
		it "should not crash when searching with date", (done)->
			admin
				.get '/cps1234/blog?search=Jan+1+2014...Jan+1+2015'
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should not crash with garbage search date ranges", (done)->
			admin
				.get '/cps1234/blog?search=Jan+100+2014...Jan+200+2015'
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should not crash when searching", (done)->
			err <- async.parallel [
				(cont)->
					student
						.get '/cps1234/blog?search=title'
						.end (err, res)->
							expect res.status .to.equal 200
							cont err
				(cont)->
					faculty
						.get '/cps1234/blog?search=title'
						.end (err, res)->
							expect res.status .to.equal 200
							cont err
				(cont)->
					admin
						.get '/cps1234/blog?search=title'
						.end (err, res)->
							expect res.status .to.equal 200
							cont err
				(cont)->
					admin
						.get '/cps1234/blog/title?action=search'
						.end (err, res)->
							expect res.status .to.equal 200
							cont err
			]
			done err
		it "should not crash when searching (more)", (done)->
			err <- async.parallel [
				(cont)->
					student
						.get '/cps1234/blog?search=not+a+title'
						.end (err, res)->
							expect res.status .to.equal 200
							cont err
				(cont)->
					faculty
						.get '/cps1234/blog?search=not+a+title'
						.end (err, res)->
							expect res.status .to.equal 200
							cont err
				(cont)->
					admin
						.get '/cps1234/blog?search=not+a+title'
						.end (err, res)->
							expect res.status .to.equal 200
							cont err
				(cont)->
					admin
						.get '/cps1234/blog/not a title?action=search'
						.end (err, res)->
							expect res.status .to.equal 200
							cont err
			]
			done err
		it "setting up for testing edit/delete", (done)->
			err <- async.parallel [
				(cont)->
					admin
						.post '/test/getpid/cps1234'
						.send {}
						.end (err, res)->
							blogpid.0 := res.body.0._id
							cont err
				(cont)->
					admin
						.post '/test/getpid/cps4601'
						.send {}
						.end (err, res)->
							blogpid.1 := res.body.0._id
							cont err
			]
			done err
				# get a pid to a post here
		it "should not allow student in the course to edit or delete blog posts", (done)->
			err <- async.parallel [
				(cont)->
					student
						.post '/cps1234/blog/title?action=edit&hmo=PUT'
						.send {
							'pid':blogpid.0
							'title':'anything'
							'text':'anything'
						}
						.end (err, res)->
							expect res.header.location .to.equal '/'
							cont err
				(cont)->
					student
						.post '/cps1234/blog/title?action=delete&hmo=DELETE'
						.send {
							'pid':blogpid.0
						}
						.end (err, res)->
							expect res.header.location .to.equal '/'
							cont err
				(cont)->
					student
						.post '/cps1234/blog/title?action=deleteall&hmo=DELETE'
						.send {
							'pid':blogpid.0
						}
						.end (err, res)->
							expect res.header.location .to.equal '/'
							cont err
			]
			done err
		it "should not allow student not in the course to edit or delete blog posts", (done)->
			err <- async.parallel [
				(cont)->
					student
						.post '/cps4601/blog/title?action=edit&hmo=PUT'
						.send {
							'pid':blogpid.1
							'title':'anything'
							'text':'anything'
						}
						.end (err, res)->
							expect res.header.location .to.equal '/'
							cont err
				(cont)->
					student
						.post '/cps4601/blog/title?action=delete&hmo=DELETE'
						.send {
							'pid':blogpid.1
						}
						.end (err, res)->
							expect res.header.location .to.equal '/'
							cont err
				(cont)->
					student
						.post '/cps4601/blog/title?action=deleteall&hmo=DELETE'
						.send {
							'pid':blogpid.1
						}
						.end (err, res)->
							expect res.header.location .to.equal '/'
							cont err
			]
			done err
		it "should allow faculty in the course to see the blog's edit or delete view", (done)->
			err <- async.parallel [
				(cont)->
					faculty
						.get '/cps1234/blog/title?action=edit'
						.end (err, res)->
							expect res.status .to.equal 200
							cont err
				(cont)->
					faculty
						.get '/cps1234/blog/title?action=delete'
						.end (err, res)->
							expect res.status .to.equal 200
							cont err
			]
			done err
		it "should allow faculty in the course to actually edit or delete the blog posts", (done)->
			err <- async.parallel [
				(cont)->
					faculty
						.post '/cps1234/blog/title?action=edit&hmo=PUT'
						.send {
							'pid':blogpid.0
							'title':'anything'
							'text':'faculty edit'
						}
						.end (err, res)->
							expect res.header.location .to.equal '/cps1234/blog/title?action=edit&success=yes'
							expect res.status .to.equal 302
							cont err
				(cont)->
					faculty
						.post '/cps1234/blog/title?action=delete&hmo=DELETE'
						.send {
							'pid':blogpid.0
						}
						.end (err, res)->
							expect res.header.location .to.equal '/cps1234/blog?action=delete&success=yes'
							expect res.status .to.equal 302
							cont err
				(cont)->
					faculty
						.post '/cps1234/blog/title?action=delete&hmo=DELETE'
						.send {
							'pid':blogpid.0
						}
						.end (err, res)->
							expect res.header.location .to.equal '/cps1234/blog?action=delete&success=yes'
							expect res.status .to.equal 302
							cont err
			]
			done err
		it "should not allow faculty not in the the course to edit or delete blog posts", (done)->
			err <- async.parallel [
				(cont)->
					faculty
						.get '/cps4601/blog/title?action=edit'
						.end (err, res)->
							expect res.status .to.not.equal 200
							cont err
				(cont)->
					faculty
						.get '/cps4601/blog/title?action=delete'
						.end (err, res)->
							expect res.status .to.not.equal 200
							cont err
				(cont)->
					faculty
						.post '/cps4601/blog/title?action=edit&hmo=PUT'
						.send {
							'pid':blogpid.0
							'title':'anything'
							'text':'anything'
						}
						.end (err, res)->
							expect res.header.location .to.not.equal '/cps4601/blog/title?action=edit&success=yes'
							expect res.status .to.not.equal 302
							cont err
				(cont)->
					faculty
						.post '/cps4601/blog/title?action=delete&hmo=DELETE'
						.send {
							'pid':blogpid.0
						}
						.end (err, res)->
							expect res.header.location .to.not.equal '/cps1234/blog?action=delete&success=yes'
							expect res.status .to.not.equal 302
							cont err
				(cont)->
					faculty
						.post '/cps4601/blog/title?action=deleteall&hmo=DELETE'
						.send {
							'pid':blogpid.0
						}
						.end (err, res)->
							expect res.header.location .to.not.equal '/cps1234/blog?action=delete&success=yes'
							expect res.status .to.not.equal 302
							cont err
			]
			done err
		it "should not allow blank blog fields", (done)->
			err <- async.parallel [
				(cont)->
					admin
						.post '/cps1234/blog?action=new'
						.send {
							'pid':blogpid.0
							'title':'title'
							'text':''
						}
						.end (err, res)->
							expect res.status .to.equal 400
							cont err
				(cont)->
					admin
						.post '/cps1234/blog?action=new'
						.send {
							'pid':blogpid.0
							'title':''
							'text':'body'
						}
						.end (err, res)->
							expect res.status .to.equal 400
							cont err
				(cont)->
					admin
						.post '/cps1234/blog/title?action=edit&hmo=PUT'
						.send {
							'pid':blogpid.0
							'title':'title'
							'text':''
						}
						.end (err, res)->
							expect res.status .to.equal 400
							cont err
				(cont)->
					admin
						.post '/cps1234/blog/title?action=edit&hmo=PUT'
						.send {
							'pid':blogpid.0
							'title':''
							'text':'body'
						}
						.end (err, res)->
							expect res.status .to.equal 400
							cont err
			]
			done err
		it "should allow admin to see blog view of edit or delete blog posts", (done)->
			err <- async.parallel [
				(cont)->
					admin
						.get '/cps1234/blog/title?action=edit'
						.end (err, res)->
							expect res.status .to.equal 200
							cont err
				(cont)->
					admin
						.get '/cps1234/blog/title?action=delete'
						.end (err, res)->
							expect res.status .to.equal 200
							cont err
				(cont)->
					admin
						.get '/cps4601/blog/title?action=edit'
						.end (err, res)->
							expect res.status .to.equal 200
							cont err
				(cont)->
					admin
						.get '/cps4601/blog/title?action=delete'
						.end (err, res)->
							expect res.status .to.equal 200
							cont err
			]
			done err
		it "should allow admin to actually edit or delete posts", (done)->
			err <- async.parallel [
				(cont)->
					admin
						.post '/cps1234/blog/title?action=edit&hmo=PUT'
						.send {
							'pid':blogpid.0
							'title':'anything'
							'text':'anything'
						}
						.end (err, res)->
							expect res.header.location .to.equal '/cps1234/blog/title?action=edit&success=yes'
							expect res.status .to.equal 302
							cont err
				(cont)->
					admin
						.post '/cps1234/blog/title?action=delete&hmo=DELETE'
						.send {
							'pid':blogpid.0
						}
						.end (err, res)->
							expect res.header.location .to.equal '/cps1234/blog?action=delete&success=yes'
							expect res.status .to.equal 302
							cont err
				(cont)->
					admin
						.post '/cps1234/blog/title?action=deleteall&hmo=DELETE'
						.send {
							'pid':blogpid.0
						}
						.end (err, res)->
							expect res.header.location .to.equal '/cps1234/blog?action=delete&success=yes'
							expect res.status .to.equal 302
							cont err
			]
			done err
		it "should not allow cross contamination of new/edit/delete posts", (done)->
			err <- async.parallel [
				(cont)->
					admin
						.post '/cps1234/blog/title?action=delete&hmo=PUT'
						.send {
							'pid':blogpid.0
							'title':'anything'
							'text':'anything'
						}
						.end (err, res)->
							expect res.status .to.not.equal 302
							cont err
				(cont)->
					admin
						.post '/cps1234/blog/title?action=edit&hmo=DELETE'
						.send {
							'pid':blogpid.0
						}
						.end (err, res)->
							expect res.status .to.not.equal 302
							cont err
				(cont)->
					admin
						.post '/cps1234/blog/title?action=new&hmo=DELETE'
						.send {
							'pid':blogpid.0
						}
						.end (err, res)->
							expect res.status .to.not.equal 302
							cont err
			]
			done err
		it "should redirect if editing nothing", (done)->
			err <- async.parallel [
				(cont)->
					admin
						.get '/cps1234/blog?action=edit'
						.end (err, res)->
							# console.log res
							expect res.header.location .to.equal '/cps1234/blog'
							expect res.status .to.equal 302
							cont err
				(cont)->
					admin
						.get '/cps1234/blog?action=delete'
						.end (err, res)->
							expect res.header.location .to.equal '/cps1234/blog'
							expect res.status .to.equal 302
							cont err
				(cont)->
					faculty
						.get '/cps1234/blog/que?action=edit'
						.end (err, res)->
							# console.log res
							expect res.header.location .to.equal '/cps1234/blog'
							expect res.status .to.equal 302
							cont err
				(cont)->
					faculty
						.get '/cps1234/blog/que?action=delete'
						.end (err, res)->
							expect res.header.location .to.equal '/cps1234/blog'
							expect res.status .to.equal 302
							cont err
			]
			done err
