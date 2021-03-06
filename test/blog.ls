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
var outside, student, faculty, admin, courseId, blogpid
blogpid = []
outside = req.agent app
student = req.agent app
faculty = req.agent app
admin = req.agent app
describe "Blog", (...)!->
	before (done)!->
		this.timeout = 0
		err <- async.parallel [
			(next)!->
				err, course <- Course.findOne {
					"school":app.locals.school
					"id":"cps1234"
				}
				.exec
				courseId := course._id.toString!
				next err
			(next)!->
				student
					.post "/login"
					.send {
						"username": "student"
						"password": "password"
					}
					.end (err, res)!->
						next err
			(next)!->
				faculty
					.post "/login"
					.send {
						"username":"faculty"
						"password":"password"
					}
					.end (err, res)!->
						next err
			(next)!->
				admin
					.post "/login"
					.send {
						"username":"admin"
						"password":"password"
					}
					.end (err, res)!->
						next err
		]
		done err
	beforeEach (done)!->
		this.timeout = 0
		admin
			.post "/test/postblog"
			.send {
				"course":"cps1234"
				"title":"title"
				"text":"text"
			}
			.end (err, res)!->
				expect res.status .to.equal 200
				done err
	after (done)!->
		this.timeout = 0
		err <- async.parallel [
			(cont)!->
				admin
					.get "/test/deleteposts/cps1234"
					.end (err, res)!->
						cont err
			(cont)!->
				admin
					.get "/test/deleteposts/cps1234"
					.end (err, res)!->
						cont err
		]
		done err
	describe "(User: Admin)", (...)!->
		it "should be visible", (done)!->
			admin
				.get "/c/#{courseId}/blog"
				.expect 200
				.end (err, res)!->
					done err
		it "should create new posts", (done)!->
			admin
				.post "/c/#{courseId}/blog?action=new"
				.send {
					"title":"admin created title"
					"text":"admin created text"
				}
				.expect 302
				.end (err, res)!->
					done err
		it "should return create post page", (done)!->
			admin
				.get "/c/#{courseId}/blog?action=new"
				.expect 200
				.end (err, res)!->
					done err
		it "should return edit post page", (done)!->
			admin
				.get "/c/#{courseId}/blog/title?action=edit"
				.expect 200
				.end (err, res)!->
					done err
		it "should return delete post page", (done)!->
			admin
				.get "/c/#{courseId}/blog/title?action=delete"
				.expect 200
				.end (err, res)!->
					done err
		it "is not a test", (done)!->
			err <- async.parallel [
				(cont)!->
					admin
						.post "/c/#{courseId}/blog?action=new"
						.send {
							"title":"title"
							"text":"student"
						}
						.expect 302
						.end (err, res)!->
							done err
				(cont)!->
					admin
						.post "/test/getpid/cps1234"
						.send {}
						.end (err, res)!->
							blogpid.0 := res.body.0._id
							cont err
			]
			done err
		it "should edit a post", (done)!->
			admin
				.post "/c/#{courseId}/blog/title?action=edit&hmo=PUT"
				.send {
					"pid":blogpid.0
					"title":"admin-created-title"
					"text":"admin-created-text"
				}
				.end (err, res)!->
					expect res.header.location .to.equal "/c/#{courseId}/blog/admin-created-title?success=yes"
					expect res.status .to.equal 302
					done err
		it "should delete a post", (done)!->
			admin
				.post "/c/#{courseId}/blog/title?action=delete&hmo=DELETE"
				.send {
					"pid":blogpid.0
				}
				.end (err, res)!->
					expect res.header.location .to.equal "/c/#{courseId}/blog?action=delete&success=yes"
					expect res.status .to.equal 302
					done err
		it "should delete all posts", (done)!->
			admin
				.post "/c/#{courseId}/blog/title?action=deleteall&hmo=DELETE"
				.send {
					"pid":blogpid.0
				}
				.end (err, res)!->
					expect res.header.location .to.equal "/c/#{courseId}/blog?action=delete&success=yes"
					expect res.status .to.equal 302
					done err
	describe "(User: Faculty)", (...)!->
		it "should be visible", (done)!->
			faculty
				.get "/c/#{courseId}/blog"
				.expect 200
				.end (err, res)!->
					done err
		it "should create new posts", (done)!->
			faculty
				.post "/c/#{courseId}/blog?action=new"
				.send {
					"title":"title"
					"text":"student"
				}
				.expect 302
				.end (err, res)!->
					done err
		it "should return create post page", (done)!->
			faculty
				.get "/c/#{courseId}/blog?action=new"
				.expect 200
				.end (err, res)!->
					done err
		it "should return edit post page", (done)!->
			faculty
				.get "/c/#{courseId}/blog/title?action=edit"
				.expect 200
				.end (err, res)!->
					done err
		it "should return delete post page", (done)!->
			faculty
				.get "/c/#{courseId}/blog/title?action=delete"
				.expect 200
				.end (err, res)!->
					done err
		it "is not a test", (done)!->
			err <- async.parallel [
				(cont)!->
					admin
						.post "/c/#{courseId}/blog?action=new"
						.send {
							"title":"title"
							"text":"student"
						}
						.expect 302
						.end (err, res)!->
							done err
				(cont)!->
					admin
						.post "/test/getpid/cps1234"
						.send {}
						.end (err, res)!->
							blogpid.0 := res.body.0._id
							cont err
			]
			done err
		it "should edit a post", (done)!->
			faculty
				.post "/c/#{courseId}/blog/title?action=edit&hmo=PUT"
				.send {
					"pid":blogpid.0
					"title":"faculty-created-title"
					"text":"faculty-created-text"
				}
				.end (err, res)!->
					expect res.header.location .to.equal "/c/#{courseId}/blog/faculty-created-title?success=yes"
					expect res.status .to.equal 302
					done err
		it "should delete a post", (done)!->
			faculty
				.post "/c/#{courseId}/blog/title?action=delete&hmo=DELETE"
				.send {
					"pid":blogpid.0
				}
				.end (err, res)!->
					expect res.header.location .to.equal "/c/#{courseId}/blog?action=delete&success=yes"
					expect res.status .to.equal 302
					done err
		it "should delete all posts", (done)!->
			faculty
				.post "/c/#{courseId}/blog/title?action=deleteall&hmo=DELETE"
				.end (err, res)!->
					expect res.header.location .to.equal "/c/#{courseId}/blog?action=delete&success=yes"
					expect res.status .to.equal 302
					done err
	describe "(User: Student)", (...)!->
		it "should be visible", (done)!->
			student
				.get "/c/#{courseId}/blog"
				.expect 200
				.end (err, res)!->
					done err
		it "should not to create new posts", (done)!->
			student
				.post "/c/#{courseId}/blog?action=new"
				.send {
					"title":"student-created-title"
					"text":"student-created-text"
				}
				.expect 302
				.end (err, res)!->
					expect res.header.location .to.not.equal "/c/#{courseId}/blog/student-created-title?success=yes"
					done err
		it "should not return create post page", (done)!->
			student
				.get "/c/#{courseId}/blog?action=new"
				.expect 302
				.end (err, res)!->
					done err
		it "should not return edit post page", (done)!->
			student
				.get "/c/#{courseId}/blog?action=edit"
				.expect 302
				.end (err, res)!->
					done err
		it "should not return edit post page", (done)!->
			student
				.get "/c/#{courseId}/blog?action=edit"
				.expect 302
				.end (err, res)!->
					done err
		it "should not return delete post page", (done)!->
			student
				.get "/c/#{courseId}/blog?action=delete"
				.expect 302
				.end (err, res)!->
					done err
		it "is not a test", (done)!->
			err <- async.parallel [
				(cont)!->
					admin
						.post "/c/#{courseId}/blog?action=new"
						.send {
							"title":"title"
							"text":"student"
						}
						.end (err, res)!->
							done err
				(cont)!->
					admin
						.post "/test/getpid/cps1234"
						.send {}
						.end (err, res)!->
							blogpid.0 := res.body.0._id
							cont err
			]
			done err
		it "should not edit a post", (done)!->
			student
				.post "/c/#{courseId}/blog/title?action=edit&hmo=PUT"
				.send {
					"pid":blogpid.0
					"title":"anything"
					"text":"anything"
				}
				.end (err, res)!->
					expect res.header.location .to.equal "/"
					done err
		it "should not delete a post", (done)!->
			student
				.post "/c/#{courseId}/blog/title?action=delete&hmo=DELETE"
				.send {
					"pid":blogpid.0
				}
				.end (err, res)!->
					expect res.header.location .to.equal "/"
					done err
		it "should not delete all posts", (done)!->
			student
				.post "/c/#{courseId}/blog/title?action=deleteall&hmo=DELETE"
				.end (err, res)!->
					expect res.header.location .to.equal "/"
					done err
	describe "(User: Outside)", (...)!->
		it "should not be visible", (done)!->
			outside
				.get "/c/#{courseId}/blog"
				.expect 302
				.end (err, res)!->
					done err
		it "should create new posts", (done)!->
			outside
				.post "/c/#{courseId}/blog?action=new"
				.send {
					"title":"title"
					"text":"student"
				}
				.expect 302
				.end (err, res)!->
					done err
		it "should return create post page", (done)!->
			outside
				.get "/c/#{courseId}/blog?action=new"
				.expect 302
				.end (err, res)!->
					done err
		it "should return edit post page", (done)!->
			outside
				.get "/c/#{courseId}/blog?action=edit"
				.expect 302
				.end (err, res)!->
					done err
		it "should return delete post page", (done)!->
			outside
				.get "/c/#{courseId}/blog?action=delete"
				.expect 302
				.end (err, res)!->
					done err
		it "is not a test", (done)!->
			err <- async.parallel [
				(cont)!->
					admin
						.post "/c/#{courseId}/blog?action=new"
						.send {
							"title":"title"
							"text":"student"
						}
						.end (err, res)!->
							done err
				(cont)!->
					admin
						.post "/test/getpid/cps1234"
						.send {}
						.end (err, res)!->
							blogpid.0 := res.body.0._id
							cont err
			]
			done err
		it "should not edit a post", (done)!->
			outside
				.post "/c/#{courseId}/blog/title?action=edit&hmo=PUT"
				.send {
					"pid":blogpid.0
					"title":"anything"
					"text":"anything"
				}
				.expect 302
				.end (err, res)!->
					expect res.header.location .to.equal "/login"
					done err
		it "should not delete a post", (done)!->
			outside
				.post "/c/#{courseId}/blog/title?action=delete&hmo=DELETE"
				.send {
					"pid":blogpid.0
				}
				.expect 302
				.end (err, res)!->
					expect res.header.location .to.equal "/login"
					done err
		it "should not delete all posts", (done)!->
			outside
				.post "/c/#{courseId}/blog/title?action=deleteall&hmo=DELETE"
				.expect 302
				.end (err, res)!->
					expect res.header.location .to.equal "/login"
					done err
	it "should return an error on a bad course", (done)!->
		admin
			.get "/cpsWHAT/blog"
			.end (err, res)!->
				expect res.status .to.not.equal 200
				done err
	it "should return an error on a bad course while editing", (done)!->
		admin
			.post "/cpsWHAT/blog?action=edit&hmo=PUT"
			.end (err, res)!->
				expect res.status .to.not.equal 200
				done err
	it "should not crash when searching with date", (done)!->
		admin
			.get "/c/#{courseId}/blog?search=Jan+1+2014...Jan+1+2015"
			.end (err, res)!->
				expect res.status .to.equal 200
				done err
	it "should not crash with garbage search date ranges", (done)!->
		admin
			.get "/c/#{courseId}/blog?search=Jan+100+2014...Jan+200+20015"
			.end (err, res)!->
				expect res.status .to.equal 200
				done err
	it "should not crash when searching 1", (done)!->
		err <- async.parallel [
			(cont)!->
				student
					.get "/c/#{courseId}/blog?search=title"
					.end (err, res)!->
						expect res.status .to.equal 200
						cont err
			(cont)!->
				faculty
					.get "/c/#{courseId}/blog?search=title"
					.end (err, res)!->
						expect res.status .to.equal 200
						cont err
		]
		done err
	it "should not crash when searching 2", (done)!->
		err <- async.parallel [
			(cont)!->
				admin
					.get "/c/#{courseId}/blog?search=title"
					.end (err, res)!->
						expect res.status .to.equal 200
						cont err
			(cont)!->
				admin
					.get "/c/#{courseId}/blog/title?action=search"
					.end (err, res)!->
						expect res.status .to.equal 200
						cont err
		]
		done err
	it "should not crash when searching 3", (done)!->
		err <- async.parallel [
			(cont)!->
				student
					.get "/c/#{courseId}/blog?search=not+a+title"
					.end (err, res)!->
						expect res.status .to.equal 200
						cont err
			(cont)!->
				faculty
					.get "/c/#{courseId}/blog?search=not+a+title"
					.end (err, res)!->
						expect res.status .to.equal 200
						cont err
		]
		done err
	it "should not crash when searching 4", (done)!->
		err <- async.parallel [
			(cont)!->
				admin
					.get "/c/#{courseId}/blog?search=not+a+title"
					.end (err, res)!->
						expect res.status .to.equal 200
						cont err
			(cont)!->
				admin
					.get "/c/#{courseId}/blog/not a title?action=search"
					.end (err, res)!->
						expect res.status .to.equal 200
						cont err
		]
		done err
	it "should not allow blank blog fields", (done)!->
		this.timeout = 4000
		err <- async.parallel [
			(cont)!->
				admin
					.post "/c/#{courseId}/blog?action=new"
					.send {
						"pid":blogpid.0
						"title":"title"
						"text":""
					}
					.end (err, res)!->
						expect res.status .to.equal 400
						cont err
			(cont)!->
				admin
					.post "/c/#{courseId}/blog?action=new"
					.send {
						"pid":blogpid.0
						"title":""
						"text":"body"
					}
					.end (err, res)!->
						expect res.status .to.equal 400
						cont err
			(cont)!->
				admin
					.post "/c/#{courseId}/blog/title?action=edit&hmo=PUT"
					.send {
						"pid":blogpid.0
						"title":"title"
						"text":""
					}
					.end (err, res)!->
						expect res.status .to.equal 400
						cont err
			(cont)!->
				admin
					.post "/c/#{courseId}/blog/title?action=edit&hmo=PUT"
					.send {
						"pid":blogpid.0
						"title":""
						"text":"body"
					}
					.end (err, res)!->
						expect res.status .to.equal 400
						cont err
		]
		done err
	it "should not allow cross contamination of new/edit/delete posts", (done)!->
		this.timeout = 3000
		err <- async.parallel [
			(cont)!->
				admin
					.post "/c/#{courseId}/blog/title?action=delete&hmo=PUT"
					.send {
						"pid":blogpid.0
						"title":"anything"
						"text":"anything"
					}
					.end (err, res)!->
						expect res.status .to.not.equal 302
						cont err
			(cont)!->
				admin
					.post "/c/#{courseId}/blog/title?action=edit&hmo=DELETE"
					.send {
						"pid":blogpid.0
					}
					.end (err, res)!->
						expect res.status .to.not.equal 302
						cont err
			(cont)!->
				admin
					.post "/c/#{courseId}/blog/title?action=new&hmo=DELETE"
					.send {
						"pid":blogpid.0
					}
					.end (err, res)!->
						expect res.status .to.not.equal 302
						cont err
		]
		done err
	it "should redirect if editing nothing", (done)!->
		this.timeout = 4000
		err <- async.parallel [
			(cont)!->
				admin
					.get "/c/#{courseId}/blog?action=edit"
					.end (err, res)!->
						expect res.header.location .to.equal "/c/#{courseId}/blog"
						expect res.status .to.equal 302
						cont err
			(cont)!->
				admin
					.get "/c/#{courseId}/blog?action=delete"
					.end (err, res)!->
						expect res.header.location .to.equal "/c/#{courseId}/blog"
						expect res.status .to.equal 302
						cont err
			(cont)!->
				faculty
					.get "/c/#{courseId}/blog/que?action=edit"
					.end (err, res)!->
						expect res.header.location .to.equal "/c/#{courseId}/blog"
						expect res.status .to.equal 302
						cont err
			(cont)!->
				faculty
					.get "/c/#{courseId}/blog/que?action=delete"
					.end (err, res)!->
						expect res.header.location .to.equal "/c/#{courseId}/blog"
						expect res.status .to.equal 302
						cont err
		]
		done err
