require! {
	"async"
	"chai" # assert lib
	"del" # delete
	"lodash"
	"moment"
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
var agent, student, faculty, admin, courseId, blogpid
assignid = []
outside = req.agent app
student = req.agent app
faculty = req.agent app
admin = req.agent app
describe "Conference" ->
	before (done)->
		err, course <- Course.findOne {
			"school":app.locals.school
			"id":"cps1234"
		}
		.exec
		courseId := course._id.toString!
		done err
	before (done)->
		student
			.post "/login"
			.send {
				"username": "student"
				"password": "password"
			}
			.end (err, res)->
				expect res.status .to.equal 302
				done err
	before (done)->
		faculty
			.post "/login"
			.send {
				"username":"faculty"
				"password":"password"
			}
			.end (err, res)->
				expect res.status .to.equal 302
				done!
	before (done)->
		admin
			.post "/login"
			.send {
				"username":"admin"
				"password":"password"
			}
			.end (err, res)->
				expect res.status .to.equal 302
				done!
	after (done)->
		admin
			.get "/test/deletethreads/cps1234"
			.end (err, res)->
				done err
	describe "(User: Admin)", (...)->
		before (done)->
			this.timeout = 0
			err <- async.waterfall [
				(cont)->
					faculty
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							cont err, res.body
				(tid,cont)->
					faculty
						.post "/c/#{courseId}/conference?action=newthread"
						.send {
							title:"facultyThread"
							text:"facultyPost"
						}
						.end (err, res)->
							faculty
								.get "/test/gettid/cps1234?title=facultyThread"
								.end (err, res)->
									cont err, res.body
				(tid,fin)->
					faculty
						.post "/c/#{courseId}/conference/#{tid.0._id.toString!}?action=newpost"
						.send {
							thread: tid.0._id.toString!
							text:"facultyPost"
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
			]
			done err
		before (done)->
			this.timeout = 3000
			err <- async.waterfall [
				(cont)->
					admin
						.get "/test/gettid/cps1234?title=adminThread"
						.end (err, res)->
							cont err, res.body
				(tid,cont)->
					admin
						.post "/c/#{courseId}/conference?action=newthread"
						.send {
							title:"adminThread"
							text:"adminPost"
						}
						.end (err, res)->
							admin
								.get "/test/gettid/cps1234?title=adminThread"
								.end (err, res)->
									cont err, res.body
				(tid,fin)->
					admin
						.post "/c/#{courseId}/conference/#{tid.0._id.toString!}?action=newpost"
						.send {
							thread: tid.0._id.toString!
							text:"adminPost"
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
			]
			done err
		after (done)->
			admin
				.get "/test/deletethreads/cps1234"
				.end (err, res)->
					done err
		it "should create a thread", (done)->
			err <- async.parallel [
				(fin)->
					admin
						.get "/c/#{courseId}/conference?action=newthread"
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
				(fin)->
					admin
						.post "/c/#{courseId}/conference?action=newthread"
						.send {
							title:"adminThread"
							text:"adminPost"
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
			]
			done err
		it "should edit their thread", (done)->
			this.timeout = 0
			err <- async.waterfall [
				(cont)->
					admin
						.get "/test/gettid/cps1234?title=adminThread"
						.end (err, res)->
							cont err, res.body
				(tid,cont)->
					err <- async.parallel [
						(fin)->
							admin
								.get "/c/#{courseId}/conference/#{tid.0._id.toString()}?action=editthread"
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
						(fin)->
							admin
								.post "/c/#{courseId}/conference/#{tid.0._id.toString()}?hmo=put&action=editthread"
								.send {
									thread: tid.0._id.toString!
									title: "adminThread"
								}
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
					]
					cont err
			]
			done err
		it "should not edit a thread that is not theirs", (done)->
			this.timeout = 0
			err <- async.waterfall [
				(cont)->
					admin
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							cont err, res.body
				(tid,cont)->
					admin
						.post "/c/#{courseId}/conference/#{tid.0._id.toString()}?hmo=put&action=editthread"
						.send {
							thread: tid.0._id.toString!
							title: "facultyThread"
						}
						.end (err, res)->
							expect res.status .to.match /^(2|3|4)/
							cont err
			]
			done err
		it "should create a post", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(fin)->
					admin
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					admin
						.post "/c/#{courseId}/conference/#{tid.0._id.toString!}?action=newpost"
						.send {
							thread: tid.0._id.toString!
							text:"adminPost"
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
			]
			done err
		it "should edit their post", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(fin)->
					admin
						.get "/test/getpost/cps1234?text=adminPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					err <- async.parallel [
						(cont)->
							admin
								.get "/c/#{courseId}/conference/#{tid.0.thread._id.toString()}/#{tid.0._id.toString()}?action=editpost"
								.end (err, res)->
									expect res.status .to.not.match /^(4|5)/
									cont err
						(cont)->
							admin
								.post "/c/#{courseId}/conference/#{tid.0.thread._id.toString()}/#{tid.0._id.toString()}?hmo=put&action=editpost"
								.send {
									thread: tid.0.thread._id.toString!
									post: tid.0._id.toString!
									text: "adminPost"
								}
								.end (err, res)->
									expect res.status .to.not.match /^(4|5)/
									cont err
					]
					fin err
			]
			done err
		it "should not edit a post that is not theirs", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(fin)->
					admin
						.get "/test/getpost/cps1234?text=facultyPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					admin
						.post "/c/#{courseId}/conference/#{tid.0.thread._id.toString()}/#{tid.0._id.toString()}?hmo=put&action=editpost"
						.send {
							thread: tid.0.thread._id.toString!
							post: tid.0._id.toString!
							text: "adminPost"
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
			]
			done err
		it "should delete their post", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(fin)->
					admin
						.get "/test/getpost/cps1234?text=adminPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					admin
						.post "/c/#{courseId}/conference/#{tid.0.thread._id.toString()}/#{tid.0._id.toString()}?hmo=delete&action=deletepost"
						.send {
							thread: tid.0.thread._id.toString!
							post: tid.0._id.toString!
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
			]
			done err
		it "should delete a post that is not theirs", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(fin)->
					admin
						.get "/test/getpost/cps1234?text=facultyPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					admin
						.post "/c/#{courseId}/conference/#{tid.0.thread._id.toString()}/#{tid.0._id.toString()}?hmo=delete&action=deletepost"
						.send {
							thread: tid.0.thread._id.toString!
							post: tid.0._id.toString!
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
			]
			done err
		it "should view thread list", (done)->
			admin
				.get "/c/#{courseId}/conference"
				.end (err, res)->
					expect res.status .to.match /^(2|3)/
					done err
		it "should view a thread", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(fin)->
					admin
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					admin
						.get "/c/#{courseId}/conference/#{tid.0._id.toString()}"
						.end (err, res)->
							expect res.status .to.match /^(2|3)/
							fin err
			]
			done err
		it "should delete a thread that is not theirs", (done)->
			this.timeout = 0
			err <- async.waterfall [
				(cont)->
					admin
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							cont err, res.body
				(tid,cont)->
					err <- async.parallel [
						(fin)->
							admin
								.get "/c/#{courseId}/conference/#{tid.0._id.toString()}?action=deletethread"
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
						(fin)->
							admin
								.post "/c/#{courseId}/conference/#{tid.0._id.toString()}?hmo=delete&action=deletethread"
								.send {
									thread: tid.0._id.toString!
								}
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
					]
					cont err
			]
			done err
		it "should delete their thread", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(cont)->
					admin
						.get "/test/gettid/cps1234?title=adminThread"
						.end (err, res)->
							cont err, res.body
				(tid,cont)->
					err <- async.parallel [
						(fin)->
							admin
								.get "/c/#{courseId}/conference/#{tid.0._id.toString()}?action=deletethread"
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
						(fin)->
							admin
								.post "/c/#{courseId}/conference/#{tid.0._id.toString()}?hmo=delete&action=deletethread"
								.send {
									thread: tid.0._id.toString!
								}
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
					]
					cont err
			]
			done err
	describe "(User: Faculty)", (...)->
		before (done)->
			this.timeout = 0
			err <- async.waterfall [
				(cont)->
					faculty
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							cont err, res.body
				(tid,cont)->
					faculty
						.post "/c/#{courseId}/conference?action=newthread"
						.send {
							title:"facultyThread"
							text:"facultyPost"
						}
						.end (err, res)->
							faculty
								.get "/test/gettid/cps1234?title=facultyThread"
								.end (err, res)->
									cont err, res.body
				(tid,fin)->
					faculty
						.post "/c/#{courseId}/conference/#{tid.0._id.toString!}?action=newpost"
						.send {
							thread: tid.0._id.toString!
							text:"facultyPost"
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
			]
			done err
		before (done)->
			this.timeout = 3000
			err <- async.waterfall [
				(cont)->
					admin
						.get "/test/gettid/cps1234?title=adminThread"
						.end (err, res)->
							cont err, res.body
				(tid,cont)->
					admin
						.post "/c/#{courseId}/conference?action=newthread"
						.send {
							title:"adminThread"
							text:"adminPost"
						}
						.end (err, res)->
							admin
								.get "/test/gettid/cps1234?title=adminThread"
								.end (err, res)->
									cont err, res.body
				(tid,fin)->
					admin
						.post "/c/#{courseId}/conference/#{tid.0._id.toString!}?action=newpost"
						.send {
							thread: tid.0._id.toString!
							text:"adminPost"
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
			]
			done err
		after (done)->
			admin
				.get "/test/deletethreads/cps1234"
				.end (err, res)->
					done err
		it "should create a thread", (done)->
			err <- async.parallel [
				(fin)->
					faculty
						.get "/c/#{courseId}/conference?action=newthread"
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
				(fin)->
					faculty
						.post "/c/#{courseId}/conference?action=newthread"
						.send {
							title:"facultyThread"
							text:"facultyPost"
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
			]
			done err
		it "should edit their thread", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(cont)->
					faculty
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							cont err, res.body
				(tid,cont)->
					err <- async.parallel [
						(fin)->
							faculty
								.get "/c/#{courseId}/conference/#{tid.0._id.toString()}?action=editthread"
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
						(fin)->
							faculty
								.post "/c/#{courseId}/conference/#{tid.0._id.toString()}?hmo=put&action=editthread"
								.send {
									thread: tid.0._id.toString!
									title: "facultyThread"
								}
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
					]
					cont err
			]
			done err
		it "should not edit a thread that is not theirs", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(cont)->
					faculty
						.get "/test/gettid/cps1234?title=adminThread"
						.end (err, res)->
							cont err, res.body
				(tid,cont)->
					faculty
						.post "/c/#{courseId}/conference/#{tid.0._id.toString()}?hmo=put&action=editthread"
						.send {
							thread: tid.0._id.toString!
							title: "facultyThread"
						}
						.end (err, res)->
							expect res.status .to.match /^(2|3|4)/
							cont err
			]
			done err
		it "should create a post", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(fin)->
					faculty
						.get "/test/gettid/cps1234?title=adminThread"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					faculty
						.post "/c/#{courseId}/conference/#{tid.0._id.toString!}?action=newpost"
						.send {
							thread: tid.0._id.toString!
							text:"facultyPost"
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
			]
			done err
		it "should edit their post", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(fin)->
					faculty
						.get "/test/getpost/cps1234?text=facultyPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					err <- async.parallel [
						(cont)->
							faculty
								.get "/c/#{courseId}/conference/#{tid.0.thread._id.toString!}/#{tid.0._id.toString!}?action=editpost"
								.end (err, res)->
									expect res.status .to.not.match /^(4|5)/
									cont err
						(cont)->
							faculty
								.post "/c/#{courseId}/conference/#{tid.0.thread._id.toString!}/#{tid.0._id.toString!}?hmo=put&action=editpost"
								.send {
									thread: tid.0.thread._id.toString!
									post: tid.0._id.toString!
									text: "facultyPost"
								}
								.end (err, res)->
									expect res.status .to.not.match /^(4|5)/
									cont err
					]
					fin err
			]
			done err
		it "should not edit a post that is not theirs", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(fin)->
					faculty
						.get "/test/getpost/cps1234?text=adminPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					faculty
						.post "/c/#{courseId}/conference/#{tid.0.thread._id.toString()}/#{tid.0._id.toString()}?hmo=put&action=editpost"
						.send {
							thread: tid.0.thread._id.toString!
							post: tid.0._id.toString!
							text: "facultyPost"
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
			]
			done err
		it "should delete their post", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(fin)->
					faculty
						.get "/test/getpost/cps1234?text=facultyPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					faculty
						.post "/c/#{courseId}/conference/#{tid.0.thread._id.toString()}/#{tid.0._id.toString()}?hmo=delete&action=deletepost"
						.send {
							thread: tid.0.thread._id.toString!
							post: tid.0._id.toString!
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
			]
			done err
		it "should delete a post that is not theirs", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(fin)->
					faculty
						.get "/test/getpost/cps1234?text=adminPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					faculty
						.post "/c/#{courseId}/conference/#{tid.0.thread._id.toString()}/#{tid.0._id.toString()}?hmo=delete&action=deletepost"
						.send {
							thread: tid.0.thread._id.toString!
							post: tid.0._id.toString!
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
			]
			done err
		it "should view thread list", (done)->
			faculty
				.get "/c/#{courseId}/conference"
				.end (err, res)->
					expect res.status .to.match /^(2|3)/
					done err
		it "should view a thread", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(fin)->
					faculty
						.get "/test/gettid/cps1234?title=adminThread"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					faculty
						.get "/c/#{courseId}/conference/#{tid.0._id.toString()}"
						.end (err, res)->
							expect res.status .to.match /^(2|3)/
							fin err
			]
			done err
		it "should delete a thread that is not theirs", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(cont)->
					faculty
						.get "/test/gettid/cps1234?title=adminThread"
						.end (err, res)->
							cont err, res.body
				(tid,cont)->
					err <- async.parallel [
						(fin)->
							faculty
								.get "/c/#{courseId}/conference/#{tid.0._id.toString()}?action=deletethread"
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
						(fin)->
							faculty
								.post "/c/#{courseId}/conference/#{tid.0._id.toString()}?hmo=delete&action=deletethread"
								.send {
									thread: tid.0._id.toString!
								}
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
					]
					cont err
			]
			done err
		it "should delete their thread", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(cont)->
					faculty
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							cont err, res.body
				(tid,cont)->
					err <- async.parallel [
						(fin)->
							faculty
								.get "/c/#{courseId}/conference/#{tid.0._id.toString()}?action=deletethread"
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
						(fin)->
							faculty
								.post "/c/#{courseId}/conference/#{tid.0._id.toString()}?hmo=delete&action=deletethread"
								.send {
									thread: tid.0._id.toString!
								}
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
					]
					cont err
			]
			done err
	describe "(User: Non-Faculty)", (...)->
		before (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(cont)->
					faculty
						.post "/c/#{courseId}/conference?action=newthread"
						.send {
							title:"facultyThread"
							text:"facultyPost"
						}
						.end (err, res)->
							faculty
								.get "/test/gettid/cps1234?title=facultyThread"
								.end (err, res)->
									cont err, res.body
				(tid,fin)->
					faculty
						.post "/c/#{courseId}/conference/#{tid.0._id.toString!}?action=newpost"
						.send {
							thread: tid.0._id.toString!
							text:"facultyPost"
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
			]
			done err
		before (done)->
			faculty
				.get "/logout"
				.end (err, res)->
					done err
		before (done)->
			faculty
				.post "/login"
				.send {
					"username": "gfaculty"
					"password": "password"
				}
				.end (err, res)->
					expect res.status .to.equal 302
					done err
		after (done)->
			faculty
				.get "/logout"
				.end (err, res)->
					done err
		after (done)->
			faculty
				.post "/login"
				.send {
					"username": "faculty"
					"password": "password"
				}
				.end (err, res)->
					expect res.status .to.equal 302
					done err
		after (done)->
			admin
				.get "/test/deletethreads/cps1234"
				.end (err, res)->
					done err
		it "should not create a thread", (done)->
			faculty
				.post "/c/#{courseId}/conference?action=newthread"
				.send {
					title:"anything"
					text:"anything"
				}
				.end (err, res)->
					expect res.status .to.match /^(3|4|5)/
					expect res.header.location .to.not.match /^\/c\/.{24}\/conference\/?.{24}?\/?.{24}?\/?/
					done err
		it "should not edit a thread", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(cont)->
					faculty
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							cont err, res.body
				(tid,cont)->
					err <- async.parallel [
						(fin)->
							faculty
								.get "/c/#{courseId}/conference/#{tid.0._id.toString()}?action=editthread"
								.end (err, res)->
									expect res.status .to.match /^(3|4|5)/
									expect res.header.location .to.not.match /^\/c\/.{24}\/conference\/?.{24}?\/?.{24}?\/?/
									fin err
						(fin)->
							faculty
								.post "/c/#{courseId}/conference/#{tid.0._id.toString()}?hmo=put&action=editthread"
								.send {
									thread: tid.0._id.toString!
									title: "facultyThread"
								}
								.end (err, res)->
									expect res.status .to.match /^(3|4|5)/
									expect res.header.location .to.not.match /^\/c\/.{24}\/conference\/?.{24}?\/?.{24}?\/?/
									fin err
					]
					cont err
			]
			done err
		it "should not delete a thread", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(cont)->
					faculty
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							cont err, res.body
				(tid,cont)->
					err <- async.parallel [
						(fin)->
							faculty
								.get "/c/#{courseId}/conference/#{tid.0._id.toString()}?action=deletethread"
								.end (err, res)->
									expect res.status .to.match /^(3|4|5)/
									expect res.header.location .to.not.match /^\/c\/.{24}\/conference\/?.{24}?\/?.{24}?\/?/
									fin err
						(fin)->
							faculty
								.post "/c/#{courseId}/conference/#{tid.0._id.toString()}?hmo=delete&action=deletethread"
								.send {
									thread: tid.0._id.toString!
								}
								.end (err, res)->
									expect res.status .to.match /^(3|4|5)/
									expect res.header.location .to.not.match /^\/c\/.{24}\/conference\/?.{24}?\/?.{24}?\/?/
									fin err
					]
					cont err
			]
			done err
		it "should not create a post", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(fin)->
					faculty
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					faculty
						.post "/c/#{courseId}/conference/#{tid.0._id.toString!}?action=newpost"
						.send {
							thread: tid.0._id.toString!
							text:"facultyPost"
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/c\/.{24}\/conference\/?.{24}?\/?.{24}?\/?/
							fin err
			]
			done err
		it "should not edit a post", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(fin)->
					faculty
						.get "/test/getpost/cps1234?text=facultyPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					faculty
						.post "/c/#{courseId}/conference/#{tid.0.thread._id.toString()}/#{tid.0._id.toString()}?hmo=put&action=editpost"
						.send {
							thread: tid.0.thread._id.toString!
							post: tid.0._id.toString!
							text: "facultyPost"
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/c\/.{24}\/conference\/?.{24}?\/?.{24}?\/?/
							fin err
			]
			done err
		it "should not delete a post", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(fin)->
					faculty
						.get "/test/getpost/cps1234?text=facultyPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					faculty
						.post "/c/#{courseId}/conference/#{tid.0.thread._id.toString()}/#{tid.0._id.toString()}?hmo=delete&action=deletepost"
						.send {
							thread: tid.0.thread._id.toString!
							post: tid.0._id.toString!
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/c\/.{24}\/conference\/?.{24}?\/?.{24}?\/?/
							fin err
			]
			done err
		it "should not view thread list", (done)->
			faculty
				.get "/c/#{courseId}/conference"
				.end (err, res)->
					expect res.status .to.match /^(3|4|5)/
					expect res.header.location .to.not.match /^\/c\/.{24}\/conference\/?.{24}?\/?.{24}?\/?/
					done err
		it "should not view a thread", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(fin)->
					faculty
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					faculty
						.get "/c/#{courseId}/conference/#{tid.0._id.toString()}"
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/c\/.{24}\/conference\/?.{24}?\/?.{24}?\/?/
							fin err
			]
			done err
	describe "(User: Student)", (...)->
		before (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(cont)->
					faculty
						.post "/c/#{courseId}/conference?action=newthread"
						.send {
							title:"facultyThread"
							text:"facultyPost"
						}
						.end (err, res)->
							faculty
								.get "/test/gettid/cps1234?title=facultyThread"
								.end (err, res)->
									cont err, res.body
				(tid,fin)->
					faculty
						.post "/c/#{courseId}/conference/#{tid.0._id.toString!}?action=newpost"
						.send {
							thread: tid.0._id.toString!
							text:"facultyPost"
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
			]
			done err
		after (done)->
			admin
				.get "/test/deletethreads/cps1234"
				.end (err, res)->
					done err
		it "should create a thread", (done)->
			student
				.post "/c/#{courseId}/conference?action=newthread"
				.send {
					title:"studentThread"
					text:"studentPost"
				}
				.end (err, res)->
					expect res.status .to.not.match /^(4|5)/
					done err
		it "should edit their thread", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(cont)->
					student
						.get "/test/gettid/cps1234?title=studentThread"
						.end (err, res)->
							cont err, res.body
				(tid,cont)->
					err <- async.parallel [
						(fin)->
							student
								.get "/c/#{courseId}/conference/#{tid.0._id.toString()}?action=editthread"
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
						(fin)->
							student
								.post "/c/#{courseId}/conference/#{tid.0._id.toString()}?hmo=put&action=editthread"
								.send {
									thread: tid.0._id.toString!
									title: "studentThread"
								}
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
					]
					cont err
			]
			done err
		it "should create a post", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(fin)->
					student
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					student
						.post "/c/#{courseId}/conference/#{tid.0._id.toString!}?action=newpost"
						.send {
							thread: tid.0._id.toString!
							text:"facultyPost"
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
			]
			done err
		it "should edit their post", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(fin)->
					student
						.get "/test/getpost/cps1234?text=studentPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					student
						.post "/c/#{courseId}/conference/#{tid.0.thread._id.toString()}/#{tid.0._id.toString()}?hmo=put&action=editpost"
						.send {
							thread: tid.0.thread._id.toString!
							post: tid.0._id.toString!
							text: "studentPost"
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
			]
			done err
		it "should delete their post", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(fin)->
					student
						.get "/test/getpost/cps1234?text=studentPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					student
						.post "/c/#{courseId}/conference/#{tid.0.thread._id.toString()}/#{tid.0._id.toString()}?hmo=delete&action=deletepost"
						.send {
							thread: tid.0.thread._id.toString!
							post: tid.0._id.toString!
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
			]
			done err
		it "should delete their thread", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(cont)->
					student
						.get "/test/gettid/cps1234?title=studentThread"
						.end (err, res)->
							cont err, res.body
				(tid,cont)->
					err <- async.parallel [
						(fin)->
							student
								.get "/c/#{courseId}/conference/#{tid.0._id.toString()}?action=deletethread"
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
						(fin)->
							student
								.post "/c/#{courseId}/conference/#{tid.0._id.toString()}?hmo=delete&action=deletethread"
								.send {
									thread: tid.0._id.toString!
								}
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
					]
					cont err
			]
			done err
		it "should view thread list", (done)->
			student
				.get "/c/#{courseId}/conference"
				.end (err, res)->
					expect res.status .to.match /^(2|3)/
					done err
		it "should view a thread", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(fin)->
					student
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					student
						.get "/c/#{courseId}/conference/#{tid.0._id.toString()}"
						.end (err, res)->
							expect res.status .to.match /^(2|3)/
							fin err
			]
			done err
		it "should not edit a thread that is not theirs", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(cont)->
					student
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							cont err, res.body
				(tid,cont)->
					student
						.post "/c/#{courseId}/conference/#{tid.0._id.toString()}?hmo=put&action=editthread"
						.send {
							thread: tid.0._id.toString!
							title: "facultyThread"
						}
						.expect 302
						.end (err, res)->
							expect res.header.location .to.match /^\/c\/.{24}\/conference\/?.{24}?\/?/
							cont err
			]
			done err
		it "should not edit a post that is not theirs", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(cont)->
					student
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							cont err, res.body
				(tid,cont)->
					student
						.get "/test/getpost/cps1234?text=facultyPost"
						.end (err, res)->
							cont err, tid, res.body
				(tid,pid,fin)->
					student
						.post "/c/#{courseId}/conference/#{tid.0._id.toString()}/#{pid.0._id.toString()}?hmo=put&action=editpost"
						.send {
							thread: tid.0._id.toString!
							post: pid.0._id.toString!
							text: "facultyPost"
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/c\/.{24}\/conference\/?.{24}?\/?.{24}?\/?/
							fin err
			]
			done err
		it "should not delete a thread that is not theirs", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(cont)->
					student
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							cont err, res.body
				(tid,cont)->
					student
						.post "/c/#{courseId}/conference/#{tid.0._id.toString()}?hmo=delete&action=deletethread"
						.send {
							thread: tid.0._id.toString!
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/c\/.{24}\/conference\/?.{24}?\/?.{24}?\/?/
							cont err
				(cont)->
					student
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							cont err
				(cont)->
					student
						.get "/test/getpost/cps1234?text=facultyPost"
						.end (err, res)->
							cont err
			]
			done err
		it "should not delete a post that is not theirs", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(cont)->
					student
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							cont err, res.body
				(tid,cont)->
					student
						.get "/test/getpost/cps1234?text=facultyPost"
						.end (err, res)->
							cont err, tid, res.body
				(tid,pid,fin)->
					student
						.post "/c/#{courseId}/conference/#{tid.0._id.toString()}/#{pid.0._id.toString()}?hmo=delete&action=deletepost"
						.send {
							thread: tid.0._id.toString!
							post: pid.0._id.toString!
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/c\/.{24}\/conference\/?.{24}?\/?.{24}?\/?/
							fin err
			]
			done err
	describe "(User: Non-Student)", (...)->
		before (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(cont)->
					faculty
						.post "/c/#{courseId}/conference?action=newthread"
						.send {
							title:"facultyThread"
							text:"facultyPost"
						}
						.end (err, res)->
							faculty
								.get "/test/gettid/cps1234?title=facultyThread"
								.end (err, res)->
									cont err, res.body
				(tid,fin)->
					faculty
						.post "/c/#{courseId}/conference/#{tid.0._id.toString!}?action=newpost"
						.send {
							thread: tid.0._id.toString!
							text:"facultyPost"
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
			]
			done err
		before (done)->
			student
				.get "/logout"
				.end (err, res)->
					done err
		before (done)->
			student
				.post "/login"
				.send {
					"username": "astudent"
					"password": "password"
				}
				.end (err, res)->
					expect res.status .to.equal 302
					done err
		after (done)->
			student
				.get "/logout"
				.end (err, res)->
					done err
		after (done)->
			student
				.post "/login"
				.send {
					"username": "student"
					"password": "password"
				}
				.end (err, res)->
					expect res.status .to.equal 302
					done err
		after (done)->
			admin
				.get "/test/deletethreads/cps1234"
				.end (err, res)->
					done err
		it "should not create a thread", (done)->
			student
				.post "/c/#{courseId}/conference?action=newthread"
				.send {
					title:"anything"
					text:"anything"
				}
				.end (err, res)->
					expect res.status .to.match /^(3|4|5)/
					expect res.header.location .to.not.match /^\/c\/.{24}\/conference\/?.{24}?\/?.{24}?\/?/
					done err
		it "should not edit a thread", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(cont)->
					student
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							cont err, res.body
				(tid,cont)->
					err <- async.parallel [
						(fin)->
							student
								.get "/c/#{courseId}/conference/#{tid.0._id.toString()}?action=editthread"
								.end (err, res)->
									expect res.status .to.match /^(3|4|5)/
									expect res.header.location .to.not.match /^\/c\/.{24}\/conference\/?.{24}?\/?.{24}?\/?/
									fin err
						(fin)->
							student
								.post "/c/#{courseId}/conference/#{tid.0._id.toString()}?hmo=put&action=editthread"
								.send {
									thread: tid.0._id.toString!
									title: "studentThread"
								}
								.end (err, res)->
									expect res.status .to.match /^(3|4|5)/
									expect res.header.location .to.not.match /^\/c\/.{24}\/conference\/?.{24}?\/?.{24}?\/?/
									fin err
					]
					cont err
			]
			done err
		it "should not delete a thread", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(cont)->
					student
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							cont err, res.body
				(tid,cont)->
					err <- async.parallel [
						(fin)->
							student
								.get "/c/#{courseId}/conference/#{tid.0._id.toString()}?action=deletethread"
								.end (err, res)->
									expect res.status .to.match /^(3|4|5)/
									expect res.header.location .to.not.match /^\/c\/.{24}\/conference\/?.{24}?\/?.{24}?\/?/
									fin err
						(fin)->
							student
								.post "/c/#{courseId}/conference/#{tid.0._id.toString()}?hmo=delete&action=deletethread"
								.send {
									thread: tid.0._id.toString!
								}
								.end (err, res)->
									expect res.status .to.match /^(3|4|5)/
									expect res.header.location .to.not.match /^\/c\/.{24}\/conference\/?.{24}?\/?.{24}?\/?/
									fin err
					]
					cont err
			]
			done err
		it "should not create a post", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(fin)->
					student
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					student
						.post "/c/#{courseId}/conference/#{tid.0._id.toString!}?action=newpost"
						.send {
							thread: tid.0._id.toString!
							text:"studentPost"
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/c\/.{24}\/conference\/?.{24}?\/?.{24}?\/?/
							fin err
			]
			done err
		it "should not edit a post", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(fin)->
					student
						.get "/test/getpost/cps1234?text=facultyPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					student
						.post "/c/#{courseId}/conference/#{tid.0.thread._id.toString()}/#{tid.0._id.toString()}?hmo=put&action=editpost"
						.send {
							thread: tid.0.thread._id.toString!
							post: tid.0._id.toString!
							text: "facultyPost"
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/c\/.{24}\/conference\/?.{24}?\/?.{24}?\/?/
							fin err
			]
			done err
		it "should not delete a post", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(fin)->
					student
						.get "/test/getpost/cps1234?text=facultyPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					student
						.post "/c/#{courseId}/conference/#{tid.0.thread._id.toString()}/#{tid.0._id.toString()}?hmo=delete&action=deletepost"
						.send {
							thread: tid.0.thread._id.toString!
							post: tid.0._id.toString!
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/c\/.{24}\/conference\/?.{24}?\/?.{24}?\/?/
							fin err
			]
			done err
		it "should not view thread list", (done)->
			student
				.get "/c/#{courseId}/conference"
				.end (err, res)->
					expect res.status .to.match /^(3|4|5)/
					expect res.header.location .to.not.match /^\/c\/.{24}\/conference\/?.{24}?\/?.{24}?\/?/
					done err
		it "should not view a thread", (done)->
			this.timeout = 2000
			err <- async.waterfall [
				(fin)->
					student
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					student
						.get "/c/#{courseId}/conference/#{tid.0._id.toString()}"
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/c\/.{24}\/conference\/?.{24}?\/?.{24}?\/?/
							fin err
			]
			done err
	describe "Other", (...)->
		it "should redirect outsider", (done)->
			outside
				.post "/c/#{courseId}/conference?action=newthread"
				.send {
					title: "theThread"
					text: "thePost"
				}
				.end (err, res)->
					expect res.status .to.match /^(3)/
					expect res.header.location .to.not.match /^\/c\/.{24}\/conference\/?.{24}?\/?.{24}?\/?/
					done err
		it "should not crash for bad conference length", (done)->
			# this may fail if that ends up being a real conference _id
			student
				.post "/c/#{courseId}/conference/12345678901234567890123?hmo=put&action=editthread"
				.send {
					thread: "12345678901234567890123"
				}
				.end (err, res)->
					expect res.status .to.match /^(5)/
					done err
		it "should not crash for bad conference length & bad post length", (done)->
			student
				.post "/c/#{courseId}/conference/12345678901234567890123/12345678901234567890123?hmo=put&action=editpost"
				.send {
					thread: "12345678901234567890123"
					post: "12345678901234567890123"
					text: "anyting"
				}
				.end (err, res)->
					expect res.status .to.match /^(5)/
					done err
		it "should not crash for bad post length", (done)->
			this.timeout = 3000
			err <- async.waterfall [
				(fin)->
					# create thread
					student
						.post "/c/#{courseId}/conference?action=newthread"
						.send {
							title: "theThread"
							text: "thePost"
						}
						.end (err, res)->
							fin err
				(fin)->
					# get thread _id
					student
						.get "/test/gettid/cps1234?title=theThread"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					# try to post to thread
					student
						.post "/c/#{courseId}/conference/#{tid.0._id.toString!}/12345678901234567890123?hmo=put&action=editpost"
						.send {
							thread: tid.0._id.toString!
							post: "12345678901234567890123"
							text: "deletedPost"
						}
						.end (err, res)->
							expect res.status .to.match /^(5)/
							fin err
			]
			done err
		it "should not crash for bad conference id", (done)->
			# this may fail if that ends up being a real conference _id
			student
				.post "/c/#{courseId}/conference/123456789012345678901234?hmo=put&action=editthread"
				.send {
					thread: "123456789012345678901234"
				}
				.end (err, res)->
					expect res.status .to.match /^404/
					done err
		it "should not crash for bad conference id & bad post id", (done)->
			student
				.post "/c/#{courseId}/conference/123456789012345678901234/123456789012345678901234?hmo=put&action=editpost"
				.send {
					thread: "123456789012345678901234"
					post: "123456789012345678901234"
					text: "anyting"
				}
				.end (err, res)->
					expect res.status .to.match /^404/
					done err
		it "should not crash for bad post id", (done)->
			this.timeout = 3000
			err <- async.waterfall [
				(fin)->
					# create thread
					student
						.post "/c/#{courseId}/conference?action=newthread"
						.send {
							title: "theThread"
							text: "thePost"
						}
						.end (err, res)->
							fin err
				(fin)->
					# get thread _id
					student
						.get "/test/gettid/cps1234?title=theThread"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					# try to post to thread
					student
						.post "/c/#{courseId}/conference/#{tid.0._id.toString!}/123456789012345678901234?hmo=put&action=editpost"
						.send {
							thread: tid.0._id.toString!
							post: "123456789012345678901234"
							text: "deletedPost"
						}
						.end (err, res)->
							expect res.status .to.match /^404/
							fin err
			]
			done err
		it "should not crash for bad post id", (done)->
			this.timeout = 4000
			err <- async.waterfall [
				(fin)->
					# create thread
					student
						.post "/c/#{courseId}/conference?action=newthread"
						.send {
							title: "theThread"
							text: "thePost"
						}
						.end (err, res)->
							fin err
				(fin)->
					# get thread _id
					student
						.get "/test/getpost/cps1234?text=thePost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					# delete post
					student
						.post "/c/#{courseId}/conference/#{tid.0.thread._id.toString!}/#{tid.0._id.toString!}?hmo=delete&action=deletepost"
						.send {
							thread: tid.0.thread._id.toString!
							post: tid.0._id.toString!
						}
						.end (err, res)->
							fin err, tid
				(tid,fin)->
					# try to post to thread
					student
						.get "/c/#{courseId}/conference/#{tid.0._id.toString!}"
						.end (err, res)->
							fin err
			]
			done err
		it "should not allow creating a post after the thread is deleted", (done)->
			this.timeout = 4000
			err <- async.waterfall [
				(fin)->
					# create thread
					student
						.post "/c/#{courseId}/conference?action=newthread"
						.send {
							title: "deletedThread"
							text: "deletedPost"
						}
						.end (err, res)->
							fin err
				(fin)->
					# get thread _id
					student
						.get "/test/gettid/cps1234?title=deletedThread"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					# delete thread
					student
						.post "/c/#{courseId}/conference/#{tid.0._id.toString!}?hmo=delete&action=deletethread"
						.send {
							thread: tid.0._id.toString!
						}
						.end (err, res)->
							fin err, tid
				(tid,fin)->
					# try to post to thread
					student
						.post "/c/#{courseId}/conference/#{tid.0._id.toString!}?action=newpost"
						.send {
							thread: tid.0._id.toString!
							text: "deletedPost"
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/c\/.{24}\/conference\/?.{24}?\/?.{24}?\/?/
							expect res.text .to.not.have.string "deletedPost"
							fin err
			]
			done err
		it "should error for no conference id edit/delete", (done)->
			err <- async.parallel [
				(para)->
					student
						.post "/c/#{courseId}/conference/123456789012345678901234/123456789012345678901234?hmo=put&action=editpost"
						.send {
							post: "123456789012345678901234"
							text: "anyting"
						}
						.end (err, res)->
							expect res.status .to.not.match /^(2|3)/
							para err
				(para)->
					student
						.post "/c/#{courseId}/conference/123456789012345678901234/123456789012345678901234?hmo=delete&action=deletepost"
						.send {
							post: "123456789012345678901234"
							text: "anyting"
						}
						.end (err, res)->
							expect res.status .to.not.match /^(2|3)/
							para err
			]
			done err
