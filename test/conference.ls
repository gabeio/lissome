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
describe "Conference" ->
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
				student
					.post "/login"
					.send {
						"username": "student"
						"password": "password"
					}
					.end (err, res)->
						expect res.status .to.equal 302
						next err
			(next)->
				faculty
					.post "/login"
					.send {
						"username":"faculty"
						"password":"password"
					}
					.end (err, res)->
						expect res.status .to.equal 302
						next err
			(next)->
				admin
					.post "/login"
					.send {
						"username":"admin"
						"password":"password"
					}
					.end (err, res)->
						expect res.status .to.equal 302
						next err
		]
		done err
	after (done)->
		this.timeout = 0
		admin
			.get "/test/deletethreads/cps1234"
			.end (err, res)->
				done err
	describe "(User: Admin)", (...)->
		before (done)->
			this.timeout = 0
			err <- async.parallel [
				(next)->
					err <- async.waterfall [
						(water)->
							faculty
								.get "/test/gettid/cps1234?title=facultyThread"
								.end (err, res)->
									water err, res.body
						(tid,water)->
							faculty
								.post "/c/#{courseId}/conference/newthread"
								.send {
									title:"facultyThread"
									text:"facultyPost"
								}
								.end (err, res)->
									faculty
										.get "/test/gettid/cps1234?title=facultyThread"
										.end (err, res)->
											water err, res.body
						(tid,water)->
							faculty
								.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/newpost"
								.send {
									thread: tid.0._id.toString!
									text:"facultyPost"
								}
								.end (err, res)->
									expect res.status .to.not.match /^(4|5)/
									water err
					]
					next err
				(next)->
					err <- async.waterfall [
						(water)->
							admin
								.get "/test/gettid/cps1234?title=adminThread"
								.end (err, res)->
									water err, res.body
						(tid,water)->
							admin
								.post "/c/#{courseId}/conference/newthread"
								.send {
									title:"adminThread"
									text:"adminPost"
								}
								.end (err, res)->
									admin
										.get "/test/gettid/cps1234?title=adminThread"
										.end (err, res)->
											water err, res.body
						(tid,water)->
							admin
								.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/newpost"
								.send {
									thread: tid.0._id.toString!
									text:"adminPost"
								}
								.end (err, res)->
									expect res.status .to.not.match /^(4|5)/
									water err
					]
					next err
			]
			done err
		after (done)->
			this.timeout = 0
			admin
				.get "/test/deletethreads/cps1234"
				.end (err, res)->
					done err
		it "should create a thread", (done)->
			err <- async.parallel [
				(fin)->
					admin
						.get "/c/#{courseId}/conference/newthread"
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
				(fin)->
					admin
						.post "/c/#{courseId}/conference/newthread"
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
			this.timeout = 3000
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
								.get "/c/#{courseId}/thread/#{tid.0._id.toString!}/editthread"
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
						(fin)->
							admin
								.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/editthread?hmo=put"
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
		it "should not edit their thread if no thread id", (done)->
			this.timeout = 3000
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
								.get "/c/#{courseId}/thread/#{tid.0._id.toString!}/editthread"
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
						(fin)->
							admin
								.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/editthread?hmo=put"
								.send {
									title: "adminThread"
								}
								.end (err, res)->
									expect res.status .to.not.match /^(2|3)/
									fin err
					]
					cont err
			]
			done err
		it "should not edit a thread that is not theirs", (done)->
			err <- async.waterfall [
				(cont)->
					admin
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							cont err, res.body
				(tid,cont)->
					admin
						.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/editthread?hmo=put"
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
			err <- async.waterfall [
				(fin)->
					admin
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					admin
						.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/newpost"
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
			this.timeout = 3000
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
								.get "/c/#{courseId}/post/#{tid.0._id.toString!}/editpost"
								.end (err, res)->
									expect res.status .to.not.match /^(4|5)/
									cont err
						(cont)->
							admin
								.post "/c/#{courseId}/post/#{tid.0._id.toString!}/editpost?hmo=put"
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
		it "should not edit their post if no thread id", (done)->
			this.timeout = 3000
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
								.get "/c/#{courseId}/post/#{tid.0._id.toString!}/editpost"
								.end (err, res)->
									expect res.status .to.not.match /^(4|5)/
									cont err
						(cont)->
							admin
								.post "/c/#{courseId}/post/#{tid.0._id.toString!}/editpost?hmo=put"
								.send {
									post: tid.0._id.toString!
									text: "adminPost"
								}
								.end (err, res)->
									expect res.status .to.match /^(4|5)/
									cont err
					]
					fin err
			]
			done err
		it "should not edit their post if no post id", (done)->
			this.timeout = 3000
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
								.get "/c/#{courseId}/post/#{tid.0._id.toString!}/editpost"
								.end (err, res)->
									expect res.status .to.not.match /^(4|5)/
									cont err
						(cont)->
							admin
								.post "/c/#{courseId}/post/#{tid.0._id.toString!}/editpost?hmo=put"
								.send {
									thread: tid.0.thread._id.toString!
									text: "adminPost"
								}
								.end (err, res)->
									expect res.status .to.match /^(4|5)/
									cont err
					]
					fin err
			]
			done err
		it "should not edit a post that is not theirs", (done)->
			err <- async.waterfall [
				(fin)->
					admin
						.get "/test/getpost/cps1234?text=facultyPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					admin
						.post "/c/#{courseId}/post/#{tid.0._id.toString!}/editpost?hmo=put"
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
		it "should not delete their post if no thread id", (done)->
			err <- async.waterfall [
				(fin)->
					admin
						.get "/test/getpost/cps1234?text=adminPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					admin
						.post "/c/#{courseId}/post/#{tid.0._id.toString!}/deletepost?hmo=delete"
						.send {
							post: tid.0._id.toString!
						}
						.end (err, res)->
							expect res.status .to.match /^(4|5)/
							fin err
			]
			done err
		it "should not delete their post if no post id", (done)->
			err <- async.waterfall [
				(fin)->
					admin
						.get "/test/getpost/cps1234?text=adminPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					admin
						.post "/c/#{courseId}/post/#{tid.0._id.toString!}/deletepost?hmo=delete"
						.send {
							thread: tid.0.thread._id.toString!
						}
						.end (err, res)->
							expect res.status .to.match /^(4|5)/
							fin err
			]
			done err
		it "should delete their post", (done)->
			err <- async.waterfall [
				(fin)->
					admin
						.get "/test/getpost/cps1234?text=adminPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					admin
						.post "/c/#{courseId}/post/#{tid.0._id.toString!}/deletepost?hmo=delete"
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
			err <- async.waterfall [
				(fin)->
					admin
						.get "/test/getpost/cps1234?text=facultyPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					admin
						.post "/c/#{courseId}/post/#{tid.0._id.toString!}/deletepost?hmo=delete"
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
			err <- async.waterfall [
				(fin)->
					admin
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					admin
						.get "/c/#{courseId}/thread/#{tid.0._id.toString!}"
						.end (err, res)->
							expect res.status .to.match /^(2|3)/
							fin err
			]
			done err
		it "should delete a thread that is not theirs", (done)->
			this.timeout = 3000
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
								.get "/c/#{courseId}/thread/#{tid.0._id.toString!}/deletethread"
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
						(fin)->
							admin
								.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/deletethread?hmo=delete"
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
			this.timeout = 3000
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
								.get "/c/#{courseId}/thread/#{tid.0._id.toString!}/deletethread"
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
						(fin)->
							admin
								.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/deletethread?hmo=delete"
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
			err <- async.parallel [
				(next)->
					err <- async.waterfall [
						(water)->
							faculty
								.get "/test/gettid/cps1234?title=facultyThread"
								.end (err, res)->
									water err, res.body
						(tid,water)->
							faculty
								.post "/c/#{courseId}/conference/newthread"
								.send {
									title:"facultyThread"
									text:"facultyPost"
								}
								.end (err, res)->
									faculty
										.get "/test/gettid/cps1234?title=facultyThread"
										.end (err, res)->
											water err, res.body
						(tid,water)->
							faculty
								.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/newpost"
								.send {
									thread: tid.0._id.toString!
									text:"facultyPost"
								}
								.end (err, res)->
									expect res.status .to.not.match /^(4|5)/
									water err
					]
					next err
				(next)->
					err <- async.waterfall [
						(water)->
							admin
								.get "/test/gettid/cps1234?title=adminThread"
								.end (err, res)->
									water err, res.body
						(tid,water)->
							admin
								.post "/c/#{courseId}/conference/newthread"
								.send {
									title:"adminThread"
									text:"adminPost"
								}
								.end (err, res)->
									admin
										.get "/test/gettid/cps1234?title=adminThread"
										.end (err, res)->
											water err, res.body
						(tid,water)->
							admin
								.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/newpost"
								.send {
									thread: tid.0._id.toString!
									text:"adminPost"
								}
								.end (err, res)->
									expect res.status .to.not.match /^(4|5)/
									water err
					]
					next err
			]
			done err
		after (done)->
			this.timeout = 0
			admin
				.get "/test/deletethreads/cps1234"
				.end (err, res)->
					done err
		it "should create a thread", (done)->
			err <- async.parallel [
				(fin)->
					faculty
						.get "/c/#{courseId}/conference/newthread"
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
				(fin)->
					faculty
						.post "/c/#{courseId}/conference/newthread"
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
			this.timeout = 3000
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
								.get "/c/#{courseId}/thread/#{tid.0._id.toString!}/editthread"
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
						(fin)->
							faculty
								.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/editthread?hmo=put"
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
		it "should not edit their thread if no thread id", (done)->
			this.timeout = 3000
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
								.get "/c/#{courseId}/thread/#{tid.0._id.toString!}/editthread"
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
						(fin)->
							faculty
								.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/editthread?hmo=put"
								.send {
									title: "facultyThread"
								}
								.end (err, res)->
									expect res.status .to.not.match /^(2|3)/
									fin err
					]
					cont err
			]
			done err
		it "should not edit a thread that is not theirs", (done)->
			err <- async.waterfall [
				(cont)->
					faculty
						.get "/test/gettid/cps1234?title=adminThread"
						.end (err, res)->
							cont err, res.body
				(tid,cont)->
					faculty
						.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/editthread?hmo=put"
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
			err <- async.waterfall [
				(fin)->
					faculty
						.get "/test/gettid/cps1234?title=adminThread"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					faculty
						.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/newpost"
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
			this.timeout = 3000
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
								.get "/c/#{courseId}/post/#{tid.0._id.toString!}/editpost"
								.end (err, res)->
									expect res.status .to.not.match /^(4|5)/
									cont err
						(cont)->
							faculty
								.post "/c/#{courseId}/post/#{tid.0._id.toString!}/editpost?hmo=put"
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
		it "should not edit their post if no thread id", (done)->
			this.timeout = 3000
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
								.get "/c/#{courseId}/post/#{tid.0._id.toString!}/editpost"
								.end (err, res)->
									expect res.status .to.not.match /^(4|5)/
									cont err
						(cont)->
							faculty
								.post "/c/#{courseId}/post/#{tid.0._id.toString!}/editpost?hmo=put"
								.send {
									post: tid.0._id.toString!
									text: "facultyPost"
								}
								.end (err, res)->
									expect res.status .to.match /^(4|5)/
									cont err
					]
					fin err
			]
			done err
		it "should not edit their post if no post id", (done)->
			this.timeout = 3000
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
								.get "/c/#{courseId}/post/#{tid.0._id.toString!}/editpost"
								.end (err, res)->
									expect res.status .to.not.match /^(4|5)/
									cont err
						(cont)->
							faculty
								.post "/c/#{courseId}/post/#{tid.0._id.toString!}/editpost?hmo=put"
								.send {
									thread: tid.0.thread._id.toString!
									text: "facultyPost"
								}
								.end (err, res)->
									expect res.status .to.match /^(4|5)/
									cont err
					]
					fin err
			]
			done err
		it "should not edit a post that is not theirs", (done)->
			err <- async.waterfall [
				(fin)->
					faculty
						.get "/test/getpost/cps1234?text=adminPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					faculty
						.post "/c/#{courseId}/post/#{tid.0._id.toString!}/editpost?hmo=put"
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
		it "should not delete their post if no thread id", (done)->
			err <- async.waterfall [
				(fin)->
					faculty
						.get "/test/getpost/cps1234?text=facultyPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					faculty
						.post "/c/#{courseId}/post/#{tid.0._id.toString!}/deletepost?hmo=delete"
						.send {
							post: tid.0._id.toString!
						}
						.end (err, res)->
							expect res.status .to.match /^(4|5)/
							fin err
			]
			done err
		it "should not delete their post if no post id", (done)->
			err <- async.waterfall [
				(fin)->
					faculty
						.get "/test/getpost/cps1234?text=facultyPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					faculty
						.post "/c/#{courseId}/post/#{tid.0._id.toString!}/deletepost?hmo=delete"
						.send {
							thread: tid.0.thread._id.toString!
						}
						.end (err, res)->
							expect res.status .to.match /^(4|5)/
							fin err
			]
			done err
		it "should delete their post", (done)->
			err <- async.waterfall [
				(fin)->
					faculty
						.get "/test/getpost/cps1234?text=facultyPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					faculty
						.post "/c/#{courseId}/post/#{tid.0._id.toString!}/deletepost?hmo=delete"
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
			err <- async.waterfall [
				(fin)->
					faculty
						.get "/test/getpost/cps1234?text=adminPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					faculty
						.post "/c/#{courseId}/post/#{tid.0._id.toString!}/deletepost?hmo=delete"
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
			err <- async.waterfall [
				(fin)->
					faculty
						.get "/test/gettid/cps1234?title=adminThread"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					faculty
						.get "/c/#{courseId}/thread/#{tid.0._id.toString!}"
						.end (err, res)->
							expect res.status .to.match /^(2|3)/
							fin err
			]
			done err
		it "should delete a thread that is not theirs", (done)->
			this.timeout = 3000
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
								.get "/c/#{courseId}/thread/#{tid.0._id.toString!}/deletethread"
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
						(fin)->
							faculty
								.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/deletethread?hmo=delete"
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
			this.timeout = 3000
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
								.get "/c/#{courseId}/thread/#{tid.0._id.toString!}/deletethread"
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
						(fin)->
							faculty
								.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/deletethread?hmo=delete"
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
			this.timeout = 0
			err <- async.waterfall [
				(water)->
					faculty
						.post "/c/#{courseId}/conference/newthread"
						.send {
							title:"facultyThread"
							text:"facultyPost"
						}
						.end (err, res)->
							water err
				(water)->
					faculty
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							water err, res.body
				(tid,water)->
					faculty
						.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/newpost"
						.send {
							thread: tid.0._id.toString!
							text:"facultyPost"
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							water err
				(water)->
					faculty
						.get "/logout"
						.end (err, res)->
							water err
				(water)->
					faculty
						.post "/login"
						.send {
							"username": "gfaculty"
							"password": "password"
						}
						.end (err, res)->
							expect res.status .to.equal 302
							water err
			]
			done err
		after (done)->
			this.timeout = 0
			err <- async.waterfall [
				(next)->
					faculty
						.get "/logout"
						.end (err, res)->
							next err
				(next)->
					faculty
						.post "/login"
						.send {
							"username": "faculty"
							"password": "password"
						}
						.end (err, res)->
							expect res.status .to.equal 302
							next err
				(next)->
					admin
						.get "/test/deletethreads/cps1234"
						.end (err, res)->
							next err
			]
			done err
		it "should not create a thread", (done)->
			faculty
				.post "/c/#{courseId}/conference/newthread"
				.send {
					title:"anything"
					text:"anything"
				}
				.end (err, res)->
					expect res.status .to.match /^(3|4|5)/
					expect res.header.location .to.not.match /^\/c\/.{24}\/post\/.{24}\/?/
					done err
		it "should not edit a thread", (done)->
			this.timeout = 3000
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
								.get "/c/#{courseId}/thread/#{tid.0._id.toString!}/editthread"
								.end (err, res)->
									expect res.status .to.match /^(3|4|5)/
									expect res.header.location .to.not.match /^\/c\/.{24}\/post\/.{24}\/?/
									fin err
						(fin)->
							faculty
								.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/editthread?hmo=put"
								.send {
									thread: tid.0._id.toString!
									title: "facultyThread"
								}
								.end (err, res)->
									expect res.status .to.match /^(3|4|5)/
									expect res.header.location .to.not.match /^\/c\/.{24}\/post\/.{24}\/?/
									fin err
					]
					cont err
			]
			done err
		it "should not delete a thread", (done)->
			this.timeout = 3000
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
								.get "/c/#{courseId}/thread/#{tid.0._id.toString!}/deletethread"
								.end (err, res)->
									expect res.status .to.match /^(3|4|5)/
									expect res.header.location .to.not.match /^\/c\/.{24}\/post\/.{24}\/?/
									fin err
						(fin)->
							faculty
								.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/deletethread?hmo=delete"
								.send {
									thread: tid.0._id.toString!
								}
								.end (err, res)->
									expect res.status .to.match /^(3|4|5)/
									expect res.header.location .to.not.match /^\/c\/.{24}\/post\/.{24}\/?/
									fin err
					]
					cont err
			]
			done err
		it "should not create a post", (done)->
			err <- async.waterfall [
				(fin)->
					faculty
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					faculty
						.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/newpost"
						.send {
							thread: tid.0._id.toString!
							text:"facultyPost"
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/c\/.{24}\/post\/.{24}\/?/
							fin err
			]
			done err
		it "should not edit a post", (done)->
			err <- async.waterfall [
				(fin)->
					faculty
						.get "/test/getpost/cps1234?text=facultyPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					faculty
						.post "/c/#{courseId}/post/#{tid.0._id.toString!}/editpost?hmo=put"
						.send {
							thread: tid.0.thread._id.toString!
							post: tid.0._id.toString!
							text: "facultyPost"
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/c\/.{24}\/post\/.{24}\/?/
							fin err
			]
			done err
		it "should not delete a post", (done)->
			err <- async.waterfall [
				(fin)->
					faculty
						.get "/test/getpost/cps1234?text=facultyPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					faculty
						.post "/c/#{courseId}/post/#{tid.0._id.toString!}/deletepost?hmo=delete"
						.send {
							thread: tid.0.thread._id.toString!
							post: tid.0._id.toString!
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/c\/.{24}\/post\/.{24}\/?/
							fin err
			]
			done err
		it "should not view thread list", (done)->
			faculty
				.get "/c/#{courseId}/conference"
				.end (err, res)->
					expect res.status .to.match /^(3|4|5)/
					expect res.header.location .to.not.match /^\/c\/.{24}\/post\/.{24}\/?/
					done err
		it "should not view a thread", (done)->
			err <- async.waterfall [
				(fin)->
					faculty
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					faculty
						.get "/c/#{courseId}/thread/#{tid.0._id.toString!}"
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/c\/.{24}\/post\/.{24}\/?/
							fin err
			]
			done err
	describe "(User: Student)", (...)->
		before (done)->
			this.timeout = 0
			err <- async.waterfall [
				(cont)->
					faculty
						.post "/c/#{courseId}/conference/newthread"
						.send {
							title:"facultyThread"
							text:"facultyPost"
						}
						.end (err, res)->
							cont err
				(cont)->
					faculty
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							cont err, res.body
				(tid,fin)->
					faculty
						.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/newpost"
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
			this.timeout = 0
			admin
				.get "/test/deletethreads/cps1234"
				.end (err, res)->
					done err
		it "should create a thread", (done)->
			student
				.post "/c/#{courseId}/conference/newthread"
				.send {
					title:"studentThread"
					text:"studentPost"
				}
				.end (err, res)->
					expect res.status .to.not.match /^(4|5)/
					done err
		it "should edit their thread", (done)->
			this.timeout = 3000
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
								.get "/c/#{courseId}/thread/#{tid.0._id.toString!}/editthread"
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
						(fin)->
							student
								.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/editthread?hmo=put"
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
		it "should not edit their thread if no thread id", (done)->
			this.timeout = 3000
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
								.get "/c/#{courseId}/thread/#{tid.0._id.toString!}/editthread"
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
						(fin)->
							student
								.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/editthread?hmo=put"
								.send {
									title: "studentThread"
								}
								.end (err, res)->
									expect res.status .to.not.match /^(2|3)/
									fin err
					]
					cont err
			]
			done err
		it "should create a post", (done)->
			err <- async.waterfall [
				(fin)->
					student
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					student
						.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/newpost"
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
			err <- async.waterfall [
				(fin)->
					student
						.get "/test/getpost/cps1234?text=studentPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					student
						.post "/c/#{courseId}/post/#{tid.0._id.toString!}/editpost?hmo=put"
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
		it "should not edit their post if no thread id", (done)->
			err <- async.waterfall [
				(fin)->
					student
						.get "/test/getpost/cps1234?text=studentPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					student
						.post "/c/#{courseId}/post/#{tid.0._id.toString!}/editpost?hmo=put"
						.send {
							post: tid.0._id.toString!
							text: "studentPost"
						}
						.end (err, res)->
							expect res.status .to.match /^(4|5)/
							fin err
			]
			done err
		it "should not edit their post if no post id", (done)->
			err <- async.waterfall [
				(fin)->
					student
						.get "/test/getpost/cps1234?text=studentPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					student
						.post "/c/#{courseId}/post/#{tid.0._id.toString!}/editpost?hmo=put"
						.send {
							thread: tid.0.thread._id.toString!
							text: "studentPost"
						}
						.end (err, res)->
							expect res.status .to.match /^(4|5)/
							fin err
			]
			done err
		it "should not delete their post if no thread id", (done)->
			err <- async.waterfall [
				(fin)->
					student
						.get "/test/getpost/cps1234?text=studentPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					student
						.post "/c/#{courseId}/post/#{tid.0._id.toString!}/deletepost?hmo=delete"
						.send {
						}
						.end (err, res)->
							expect res.status .to.match /^(4|5)/
							fin err
			]
			done err
		it "should not delete their post if no post id", (done)->
			err <- async.waterfall [
				(fin)->
					student
						.get "/test/getpost/cps1234?text=studentPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					student
						.post "/c/#{courseId}/post/#{tid.0._id.toString!}/deletepost?hmo=delete"
						.send {
							thread: tid.0.thread._id.toString!
						}
						.end (err, res)->
							expect res.status .to.match /^(4|5)/
							fin err
			]
			done err
		it "should delete their post", (done)->
			err <- async.waterfall [
				(fin)->
					student
						.get "/test/getpost/cps1234?text=studentPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					student
						.post "/c/#{courseId}/post/#{tid.0._id.toString!}/deletepost?hmo=delete"
						.send {
							thread: tid.0.thread._id.toString!
							post: tid.0._id.toString!
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
			]
			done err
		it "should not delete their thread if no thread id", (done)->
			this.timeout = 3000
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
								.get "/c/#{courseId}/thread/#{tid.0._id.toString!}/deletethread"
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
						(fin)->
							student
								.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/deletethread?hmo=delete"
								.send {
								}
								.end (err, res)->
									expect res.status .to.match /^(4|5)/
									fin err
					]
					cont err
			]
			done err
		it "should delete their thread", (done)->
			this.timeout = 3000
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
								.get "/c/#{courseId}/thread/#{tid.0._id.toString!}/deletethread"
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
						(fin)->
							student
								.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/deletethread?hmo=delete"
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
			err <- async.waterfall [
				(fin)->
					student
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					student
						.get "/c/#{courseId}/thread/#{tid.0._id.toString!}"
						.end (err, res)->
							expect res.status .to.match /^(2|3)/
							fin err
			]
			done err
		it "should not edit a thread that is not theirs", (done)->
			err <- async.waterfall [
				(cont)->
					student
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							cont err, res.body
				(tid,cont)->
					student
						.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/editthread?hmo=put"
						.send {
							thread: tid.0._id.toString!
							title: "facultyThread"
						}
						.expect 302
						.end (err, res)->
							expect res.header.location .to.match /^\/c\/.{24}\/thread\/.{24}\/?/
							cont err
			]
			done err
		it "should not edit a post that is not theirs", (done)->
			this.timeout = 3000
			err <- async.waterfall [
				(water)->
					err,result <- async.parallel [
						(next)->
							student
								.get "/test/gettid/cps1234?title=facultyThread"
								.end (err, res)->
									next err, { tid: res.body }
						(next)->
							student
								.get "/test/getpost/cps1234?text=facultyPost"
								.end (err, res)->
									next err, { pid: res.body }
					]
					result = _ result.0 .merge result.1 .value!
					water err, result
				(ids,water)->
					student
						.post "/c/#{courseId}/post/#{ids.pid.0._id.toString!}/editpost?hmo=put"
						.send {
							thread: ids.tid.0._id.toString!
							post: ids.pid.0._id.toString!
							text: "facultyPost"
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/c\/.{24}\/post\/.{24}\/?/
							water err
			]
			done err
		it "should not delete a thread that is not theirs", (done)->
			this.timeout = 3000
			err <- async.waterfall [
				(cont)->
					student
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							cont err, res.body
				(tid,cont)->
					student
						.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/deletethread?hmo=delete"
						.send {
							thread: tid.0._id.toString!
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/c\/.{24}\/post\/.{24}\/?/
							cont err, tid
				(tid,cont)->
					student
						.get "/c/#{courseId}/thread/#{tid.0._id.toString!}"
						.end (err, res)->
							expect res.status .to.not.match /^(3|4|5)/
							cont err
			]
			done err
		it "should not delete a post that is not theirs", (done)->
			this.timeout = 3000
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
						.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/#{pid.0._id.toString!}/deletepost?hmo=delete"
						.send {
							thread: tid.0._id.toString!
							post: pid.0._id.toString!
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/c\/.{24}\/post\/.{24}\/?/
							fin err
			]
			done err
	describe "(User: Non-Student)", (...)->
		before (done)->
			this.timeout = 0
			err <- async.waterfall [
				(next)->
					faculty
						.post "/c/#{courseId}/conference/newthread"
						.send {
							title:"facultyThread"
							text:"facultyPost"
						}
						.end (err, res)->
							next err
				(next)->
					faculty
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							next err, res.body
				(tid,next)->
					faculty
						.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/newpost"
						.send {
							thread: tid.0._id.toString!
							text:"facultyPost"
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							next err
				(next)->
					student
						.get "/logout"
						.end (err, res)->
							next err
				(next)->
					student
						.post "/login"
						.send {
							"username": "astudent"
							"password": "password"
						}
						.end (err, res)->
							expect res.status .to.equal 302
							next err
			]
			done err
		after (done)->
			this.timeout = 0
			err <- async.waterfall [
				(next)->
					student
						.get "/logout"
						.end (err, res)->
							next err
				(next)->
					student
						.post "/login"
						.send {
							"username": "student"
							"password": "password"
						}
						.end (err, res)->
							expect res.status .to.equal 302
							next err
				(next)->
					admin
						.get "/test/deletethreads/cps1234"
						.end (err, res)->
							next err
			]
			done err
		it "should not create a thread", (done)->
			student
				.post "/c/#{courseId}/conference/newthread"
				.send {
					title:"anything"
					text:"anything"
				}
				.end (err, res)->
					expect res.status .to.match /^(3|4|5)/
					expect res.header.location .to.not.match /^\/c\/.{24}\/post\/.{24}\/?/
					done err
		it "should not edit a thread", (done)->
			this.timeout = 3000
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
								.get "/c/#{courseId}/thread/#{tid.0._id.toString!}/editthread"
								.end (err, res)->
									expect res.status .to.match /^(3|4|5)/
									expect res.header.location .to.not.match /^\/c\/.{24}\/post\/.{24}\/?/
									fin err
						(fin)->
							student
								.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/editthread?hmo=put"
								.send {
									thread: tid.0._id.toString!
									title: "studentThread"
								}
								.end (err, res)->
									expect res.status .to.match /^(3|4|5)/
									expect res.header.location .to.not.match /^\/c\/.{24}\/post\/.{24}\/?/
									fin err
					]
					cont err
			]
			done err
		it "should not delete a thread", (done)->
			this.timeout = 3000
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
								.get "/c/#{courseId}/thread/#{tid.0._id.toString!}/deletethread"
								.end (err, res)->
									expect res.status .to.match /^(3|4|5)/
									expect res.header.location .to.not.match /^\/c\/.{24}\/post\/.{24}\/?/
									fin err
						(fin)->
							student
								.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/deletethread?hmo=delete"
								.send {
									thread: tid.0._id.toString!
								}
								.end (err, res)->
									expect res.status .to.match /^(3|4|5)/
									expect res.header.location .to.not.match /^\/c\/.{24}\/post\/.{24}\/?/
									fin err
					]
					cont err
			]
			done err
		it "should not create a post", (done)->
			err <- async.waterfall [
				(fin)->
					student
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					student
						.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/newpost"
						.send {
							thread: tid.0._id.toString!
							text:"studentPost"
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/c\/.{24}\/post\/.{24}\/?/
							fin err
			]
			done err
		it "should not edit a post", (done)->
			err <- async.waterfall [
				(fin)->
					student
						.get "/test/getpost/cps1234?text=facultyPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					student
						.post "/c/#{courseId}/post/#{tid.0._id.toString!}/editpost?hmo=put"
						.send {
							thread: tid.0.thread._id.toString!
							post: tid.0._id.toString!
							text: "facultyPost"
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/c\/.{24}\/post\/.{24}\/?/
							fin err
			]
			done err
		it "should not delete a post", (done)->
			err <- async.waterfall [
				(fin)->
					student
						.get "/test/getpost/cps1234?text=facultyPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					student
						.post "/c/#{courseId}/post/#{tid.0._id.toString!}/deletepost?hmo=delete"
						.send {
							thread: tid.0.thread._id.toString!
							post: tid.0._id.toString!
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/c\/.{24}\/post\/.{24}\/?/
							fin err
			]
			done err
		it "should not view thread list", (done)->
			student
				.get "/c/#{courseId}/conference"
				.end (err, res)->
					expect res.status .to.match /^(3|4|5)/
					expect res.header.location .to.not.match /^\/c\/.{24}\/post\/.{24}\/?/
					done err
		it "should not view a thread", (done)->
			err <- async.waterfall [
				(fin)->
					student
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					student
						.get "/c/#{courseId}/thread/#{tid.0._id.toString!}"
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/c\/.{24}\/post\/.{24}\/?/
							fin err
			]
			done err
	describe "Other", (...)->
		it "should redirect outsider", (done)->
			outside
				.post "/c/#{courseId}/conference/newthread"
				.send {
					title: "theThread"
					text: "thePost"
				}
				.end (err, res)->
					expect res.status .to.match /^(3)/
					expect res.header.location .to.not.match /^\/c\/.{24}\/post\/.{24}\/?/
					done err
		it "should not crash for bad conference length", (done)->
			err <- async.parallel [
				(para)->
					# this may fail if that ends up being a real conference _id
					student
						.post "/c/#{courseId}/thread/12345678901234567890123/editthread?hmo=put"
						.send {
							thread: "12345678901234567890123"
						}
						.end (err, res)->
							console.log res.headers.location if res.status is 302
							expect res.status .to.match /^(4|5)/
							para err
				(para)->
					# this may fail if that ends up being a real conference _id
					student
						.post "/c/#{courseId}/thread/1234567890123456789012345/editthread?hmo=put"
						.send {
							thread: "12345678901234567890123"
						}
						.end (err, res)->
							console.log res.headers.location if res.status is 302
							expect res.status .to.match /^(4|5)/
							para err
			]
			done err
		it "should not crash for bad post length", (done)->
			this.timeout = 3000
			err <- async.waterfall [
				(fin)->
					# create thread
					student
						.post "/c/#{courseId}/conference/newthread"
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
						.post "/c/#{courseId}/post/12345678901234567890123/editpost?hmo=put"
						.send {
							thread: tid.0._id.toString!
							post: "12345678901234567890123"
							text: "deletedPost"
						}
						.end (err, res)->
							console.log res.headers.location if res.status is 302
							expect res.status .to.match /^(4|5)/
							fin err
			]
			done err
		it "should not crash for bad conference id", (done)->
			# this may fail if that ends up being a real conference _id
			student
				.post "/c/#{courseId}/thread/123456789012345678901234/editthread?hmo=put"
				.send {
					thread: "123456789012345678901234"
				}
				.end (err, res)->
					console.log res.headers.location if res.status is 302
					expect res.status .to.match /^(4|5)/
					done err
		it "should not allow creating a post after the thread is deleted", (done)->
			this.timeout = 4000
			err <- async.waterfall [
				(fin)->
					# create thread
					student
						.post "/c/#{courseId}/conference/newthread"
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
						.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/deletethread?hmo=delete"
						.send {
							thread: tid.0._id.toString!
						}
						.end (err, res)->
							fin err, tid
				(tid,fin)->
					# try to post to thread
					student
						.post "/c/#{courseId}/thread/#{tid.0._id.toString!}/newpost"
						.send {
							thread: tid.0._id.toString!
							text: "deletedPost"
						}
						.end (err, res)->
							console.log res.headers.location if res.status is 302
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/c\/.{24}\/post\/.{24}\/?/
							expect res.text .to.not.have.string "deletedPost"
							fin err
			]
			done err
