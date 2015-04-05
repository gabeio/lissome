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
req = supertest
expect = chai.expect
assert = chai.assert
should = chai.should!
var agent, student, faculty, admin, blogpid
assignid = []
outside = req.agent app
student = req.agent app
faculty = req.agent app
admin = req.agent app
describe "Conference" ->
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
	describe "Faculty+", (...)->
		beforeEach (done)->
			err <- async.waterfall [
				(cont)->
					faculty
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							cont err, res.body
				(tid,cont)->
					if !tid? or tid.length < 1
						# console.log "created another faculty thread"
						faculty
							.post "/cps1234/conference?action=newthread"
							.send {
								title:"facultyThread"
								text:"facultyPost"
							}
							.end (err, res)->
								faculty
									.get "/test/gettid/cps1234?title=facultyThread"
									.end (err, res)->
										cont err, res.body
					else
						cont null, tid
				(tid,fin)->
					faculty
						.post "/cps1234/conference/#{tid.0._id.toString!}?action=newpost"
						.send {
							thread: tid.0._id.toString!
							text:"facultyPost"
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
			]
			done err
		beforeEach (done)->
			err <- async.waterfall [
				(cont)->
					admin
						.get "/test/gettid/cps1234?title=adminThread"
						.end (err, res)->
							cont err, res.body
				(tid,cont)->
					if !tid? or tid.length < 1
						# console.log "created another admin thread"
						admin
							.post "/cps1234/conference?action=newthread"
							.send {
								title:"adminThread"
								text:"adminPost"
							}
							.end (err, res)->
								faculty
									.get "/test/gettid/cps1234?title=facultyThread"
									.end (err, res)->
										cont err, res.body
					else
						cont null, tid
				(tid,fin)->
					admin
						.post "/cps1234/conference/#{tid.0._id.toString!}?action=newpost"
						.send {
							thread: tid.0._id.toString!
							text:"adminPost"
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
			]
			done err
		it "should allow a faculty to create a thread", (done)->
			faculty
				.post "/cps1234/conference?action=newthread"
				.send {
					title:"facultyThread"
					text:"facultyPost"
				}
				.end (err, res)->
					expect res.status .to.not.match /^(4|5)/
					done err
		it "should allow an admin to create a thread", (done)->
			admin
				.post "/cps1234/conference?action=newthread"
				.send {
					title:"adminThread"
					text:"adminPost"
				}
				.end (err, res)->
					expect res.status .to.not.match /^(4|5)/
					done err
		it "should allow a faculty to edit their thread", (done)->
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
								.get "/cps1234/conference/#{tid.0._id.toString()}?action=editthread"
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
						(fin)->
							faculty
								.post "/cps1234/conference/#{tid.0._id.toString()}?hmo=put&action=editthread"
								.send {
									thread: tid.0._id.toString()
									title: "facultyThread"
								}
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
					]
					cont err
			]
			done err
		it "should allow an admin to edit their thread", (done)->
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
								.get "/cps1234/conference/#{tid.0._id.toString()}?action=editthread"
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
						(fin)->
							admin
								.post "/cps1234/conference/#{tid.0._id.toString()}?hmo=put&action=editthread"
								.send {
									thread: tid.0._id.toString()
									title: "adminThread"
								}
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
					]
					cont err
			]
			done err
		it "should not allow a faculty to edit a thread that is not theirs", (done)->
			err <- async.waterfall [
				(cont)->
					faculty
						.get "/test/gettid/cps1234?title=adminThread"
						.end (err, res)->
							cont err, res.body
				(tid,cont)->
					faculty
						.post "/cps1234/conference/#{tid.0._id.toString()}?hmo=put&action=editthread"
						.send {
							thread: tid.0._id.toString()
							title: "facultyThread"
						}
						.end (err, res)->
							expect res.status .to.match /^(2|3|4)/
							cont err
			]
			done err
		it "should not allow an admin to edit a thread that is not theirs", (done)->
			err <- async.waterfall [
				(cont)->
					admin
						.get "/test/gettid/cps1234?title=adminThread"
						.end (err, res)->
							cont err, res.body
				(tid,cont)->
					admin
						.post "/cps1234/conference/#{tid.0._id.toString()}?hmo=put&action=editthread"
						.send {
							thread: tid.0._id.toString()
							title: "facultyThread"
						}
						.end (err, res)->
							expect res.status .to.match /^(2|3|4)/
							cont err
			]
			done err
		it "should allow a faculty to delete a thread that is not theirs", (done)->
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
								.get "/cps1234/conference/#{tid.0._id.toString()}?action=deletethread"
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
						(fin)->
							faculty
								.post "/cps1234/conference/#{tid.0._id.toString()}?hmo=delete&action=deletethread"
								.send {
									thread: tid.0._id.toString()
								}
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
					]
					cont err
			]
			done err
		it "should allow an admin to delete a thread that is not theirs", (done)->
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
								.get "/cps1234/conference/#{tid.0._id.toString()}?action=deletethread"
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
						(fin)->
							admin
								.post "/cps1234/conference/#{tid.0._id.toString()}?hmo=delete&action=deletethread"
								.send {
									thread: tid.0._id.toString()
								}
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
					]
					cont err
			]
			done err
		it "should allow a faculty to delete their thread", (done)->
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
								.get "/cps1234/conference/#{tid.0._id.toString()}?action=deletethread"
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
						(fin)->
							faculty
								.post "/cps1234/conference/#{tid.0._id.toString()}?hmo=delete&action=deletethread"
								.send {
									thread: tid.0._id.toString()
								}
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
					]
					cont err
			]
			done err
		it "should allow an admin to delete their thread", (done)->
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
								.get "/cps1234/conference/#{tid.0._id.toString()}?action=deletethread"
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
						(fin)->
							admin
								.post "/cps1234/conference/#{tid.0._id.toString()}?hmo=delete&action=deletethread"
								.send {
									thread: tid.0._id.toString()
								}
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
					]
					cont err
			]
			done err
		it "should allow a faculty to create a post", (done)->
			err <- async.waterfall [
				(fin)->
					faculty
						.get "/test/gettid/cps1234?title=adminThread"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					faculty
						.post "/cps1234/conference/#{tid.0._id.toString!}?action=newpost"
						.send {
							thread: tid.0._id.toString!
							text:"facultyPost"
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
			]
			done err
		it "should allow an admin to create a post", (done)->
			err <- async.waterfall [
				(fin)->
					admin
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					admin
						.post "/cps1234/conference/#{tid.0._id.toString!}?action=newpost"
						.send {
							thread: tid.0._id.toString!
							text:"adminPost"
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
			]
			done err
		it "should allow a faculty to edit thier post", (done)->
			err <- async.waterfall [
				(fin)->
					faculty
						.get "/test/getpost/cps1234?text=facultyPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					faculty
						.post "/cps1234/conference/#{tid.0.thread._id.toString()}/#{tid.0._id.toString()}?hmo=put&action=editpost"
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
		it "should allow an admin to edit thier post", (done)->
			err <- async.waterfall [
				(fin)->
					admin
						.get "/test/getpost/cps1234?text=adminPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					admin
						.post "/cps1234/conference/#{tid.0.thread._id.toString()}/#{tid.0._id.toString()}?hmo=put&action=editpost"
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
		it "should not allow a faculty to edit a post that is not theirs", (done)->
			err <- async.waterfall [
				(fin)->
					faculty
						.get "/test/getpost/cps1234?text=adminPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					faculty
						.post "/cps1234/conference/#{tid.0.thread._id.toString()}/#{tid.0._id.toString()}?hmo=put&action=editpost"
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
		it "should not allow an admin to edit a post that is not theirs", (done)->
			err <- async.waterfall [
				(fin)->
					admin
						.get "/test/getpost/cps1234?text=facultyPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					admin
						.post "/cps1234/conference/#{tid.0.thread._id.toString()}/#{tid.0._id.toString()}?hmo=put&action=editpost"
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
		it "should allow a faculty to delete their post", (done)->
			err <- async.waterfall [
				(fin)->
					faculty
						.get "/test/getpost/cps1234?text=facultyPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					faculty
						.post "/cps1234/conference/#{tid.0.thread._id.toString()}/#{tid.0._id.toString()}?hmo=delete&action=deletepost"
						.send {
							thread: tid.0.thread._id.toString!
							post: tid.0._id.toString!
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
			]
			done err
		it "should allow an admin to delete their post", (done)->
			err <- async.waterfall [
				(fin)->
					admin
						.get "/test/getpost/cps1234?text=adminPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					admin
						.post "/cps1234/conference/#{tid.0.thread._id.toString()}/#{tid.0._id.toString()}?hmo=delete&action=deletepost"
						.send {
							thread: tid.0.thread._id.toString!
							post: tid.0._id.toString!
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
			]
			done err
		it "should allow a faculty to delete a post that is not theirs", (done)->
			err <- async.waterfall [
				(fin)->
					faculty
						.get "/test/getpost/cps1234?text=adminPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					faculty
						.post "/cps1234/conference/#{tid.0.thread._id.toString()}/#{tid.0._id.toString()}?hmo=delete&action=deletepost"
						.send {
							thread: tid.0.thread._id.toString!
							post: tid.0._id.toString!
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
			]
			done err
		it "should allow an admin to delete a post that is not theirs", (done)->
			err <- async.waterfall [
				(fin)->
					admin
						.get "/test/getpost/cps1234?text=facultyPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					admin
						.post "/cps1234/conference/#{tid.0.thread._id.toString()}/#{tid.0._id.toString()}?hmo=delete&action=deletepost"
						.send {
							thread: tid.0.thread._id.toString!
							post: tid.0._id.toString!
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
			]
			done err
		it "should allow a faculty to view thread list", (done)->
			faculty
				.get "/cps1234/conference"
				.end (err, res)->
					expect res.status .to.match /^(2|3)/
					done err
		it "should allow an admin to view thread list", (done)->
			admin
				.get "/cps1234/conference"
				.end (err, res)->
					expect res.status .to.match /^(2|3)/
					done err
		it "should allow a faculty to view a thread", (done)->
			err <- async.waterfall [
				(fin)->
					faculty
						.get "/test/gettid/cps1234?title=adminThread"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					faculty
						.get "/cps1234/conference/#{tid.0._id.toString()}"
						.end (err, res)->
							expect res.status .to.match /^(2|3)/
							fin err
			]
			done err
		it "should allow an admin to view a thread", (done)->
			err <- async.waterfall [
				(fin)->
					admin
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					admin
						.get "/cps1234/conference/#{tid.0._id.toString()}"
						.end (err, res)->
							expect res.status .to.match /^(2|3)/
							fin err
			]
			done err
	describe "Outside Faculty", (...)->
		before (done)->
			err <- async.waterfall [
				(cont)->
					faculty
						.post "/cps1234/conference?action=newthread"
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
						.post "/cps1234/conference/#{tid.0._id.toString!}?action=newpost"
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
		it "should not allow an outside faculty to create a thread", (done)->
			faculty
				.post "/cps1234/conference?action=newthread"
				.send {
					title:"anything"
					text:"anything"
				}
				.end (err, res)->
					expect res.status .to.match /^(3|4|5)/
					expect res.header.location .to.not.match /^\/cps1234\/conference\/?.{24}?\/?.{24}?\/?/
					done err
		it "should not allow an outside faculty to edit a thread", (done)->
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
								.get "/cps1234/conference/#{tid.0._id.toString()}?action=editthread"
								.end (err, res)->
									expect res.status .to.match /^(3|4|5)/
									expect res.header.location .to.not.match /^\/cps1234\/conference\/?.{24}?\/?.{24}?\/?/
									fin err
						(fin)->
							faculty
								.post "/cps1234/conference/#{tid.0._id.toString()}?hmo=put&action=editthread"
								.send {
									thread: tid.0._id.toString()
									title: "facultyThread"
								}
								.end (err, res)->
									expect res.status .to.match /^(3|4|5)/
									expect res.header.location .to.not.match /^\/cps1234\/conference\/?.{24}?\/?.{24}?\/?/
									fin err
					]
					cont err
			]
			done err
		it "should not allow an outside faculty to delete a thread", (done)->
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
								.get "/cps1234/conference/#{tid.0._id.toString()}?action=deletethread"
								.end (err, res)->
									expect res.status .to.match /^(3|4|5)/
									expect res.header.location .to.not.match /^\/cps1234\/conference\/?.{24}?\/?.{24}?\/?/
									fin err
						(fin)->
							faculty
								.post "/cps1234/conference/#{tid.0._id.toString()}?hmo=delete&action=deletethread"
								.send {
									thread: tid.0._id.toString()
								}
								.end (err, res)->
									expect res.status .to.match /^(3|4|5)/
									expect res.header.location .to.not.match /^\/cps1234\/conference\/?.{24}?\/?.{24}?\/?/
									fin err
					]
					cont err
			]
			done err
		it "should not allow an outside faculty to create a post", (done)->
			err <- async.waterfall [
				(fin)->
					faculty
						.get "/test/gettid/cps1234?title=adminThread"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					faculty
						.post "/cps1234/conference/#{tid.0._id.toString!}?action=newpost"
						.send {
							thread: tid.0._id.toString!
							text:"facultyPost"
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/cps1234\/conference\/?.{24}?\/?.{24}?\/?/
							fin err
			]
			done err
		it "should not allow an outside faculty to edit a post", (done)->
			err <- async.waterfall [
				(fin)->
					faculty
						.get "/test/getpost/cps1234?text=facultyPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					faculty
						.post "/cps1234/conference/#{tid.0.thread._id.toString()}/#{tid.0._id.toString()}?hmo=put&action=editpost"
						.send {
							thread: tid.0.thread._id.toString!
							post: tid.0._id.toString!
							text: "facultyPost"
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/cps1234\/conference\/?.{24}?\/?.{24}?\/?/
							fin err
			]
			done err
		it "should not allow an outside faculty to delete a post", (done)->
			err <- async.waterfall [
				(fin)->
					faculty
						.get "/test/getpost/cps1234?text=facultyPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					faculty
						.post "/cps1234/conference/#{tid.0.thread._id.toString()}/#{tid.0._id.toString()}?hmo=delete&action=deletepost"
						.send {
							thread: tid.0.thread._id.toString!
							post: tid.0._id.toString!
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/cps1234\/conference\/?.{24}?\/?.{24}?\/?/
							fin err
			]
			done err
		it "should not allow an outside faculty to view thread list", (done)->
			faculty
				.get "/cps1234/conference"
				.end (err, res)->
					expect res.status .to.match /^(3|4|5)/
					expect res.header.location .to.not.match /^\/cps1234\/conference\/?.{24}?\/?.{24}?\/?/
					done err
		it "should not allow an outside faculty to view a thread", (done)->
			err <- async.waterfall [
				(fin)->
					faculty
						.get "/test/gettid/cps1234?title=adminThread"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					faculty
						.get "/cps1234/conference/#{tid.0._id.toString()}"
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/cps1234\/conference\/?.{24}?\/?.{24}?\/?/
							fin err
			]
			done err
	describe "Student", (...)->
		before (done)->
			err <- async.waterfall [
				(cont)->
					faculty
						.post "/cps1234/conference?action=newthread"
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
						.post "/cps1234/conference/#{tid.0._id.toString!}?action=newpost"
						.send {
							thread: tid.0._id.toString!
							text:"facultyPost"
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
			]
			done err
		it "should allow a student to create a thread", (done)->
			student
				.post "/cps1234/conference?action=newthread"
				.send {
					title:"studentThread"
					text:"studentPost"
				}
				.end (err, res)->
					expect res.status .to.not.match /^(4|5)/
					done err
		it "should allow a student to edit their thread", (done)->
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
								.get "/cps1234/conference/#{tid.0._id.toString()}?action=editthread"
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
						(fin)->
							student
								.post "/cps1234/conference/#{tid.0._id.toString()}?hmo=put&action=editthread"
								.send {
									thread: tid.0._id.toString()
									title: "studentThread"
								}
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
					]
					cont err
			]
			done err
		it "should allow a student to create a post", (done)->
			err <- async.waterfall [
				(fin)->
					student
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					student
						.post "/cps1234/conference/#{tid.0._id.toString!}?action=newpost"
						.send {
							thread: tid.0._id.toString!
							text:"facultyPost"
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
			]
			done err
		it "should allow a student to edit thier post", (done)->
			err <- async.waterfall [
				(fin)->
					student
						.get "/test/getpost/cps1234?text=studentPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					student
						.post "/cps1234/conference/#{tid.0.thread._id.toString()}/#{tid.0._id.toString()}?hmo=put&action=editpost"
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
		it "should allow a student to delete their post", (done)->
			err <- async.waterfall [
				(fin)->
					student
						.get "/test/getpost/cps1234?text=studentPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					student
						.post "/cps1234/conference/#{tid.0.thread._id.toString()}/#{tid.0._id.toString()}?hmo=delete&action=deletepost"
						.send {
							thread: tid.0.thread._id.toString!
							post: tid.0._id.toString!
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/
							fin err
			]
			done err
		it "should allow a student to delete their thread", (done)->
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
								.get "/cps1234/conference/#{tid.0._id.toString()}?action=deletethread"
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
						(fin)->
							student
								.post "/cps1234/conference/#{tid.0._id.toString()}?hmo=delete&action=deletethread"
								.send {
									thread: tid.0._id.toString()
								}
								.end (err, res)->
									expect res.status .to.match /^(2|3)/
									fin err
					]
					cont err
			]
			done err
		it "should allow a student to view thread list", (done)->
			student
				.get "/cps1234/conference"
				.end (err, res)->
					expect res.status .to.match /^(2|3)/
					done err
		it "should allow a student to view a thread", (done)->
			err <- async.waterfall [
				(fin)->
					student
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					student
						.get "/cps1234/conference/#{tid.0._id.toString()}"
						.end (err, res)->
							expect res.status .to.match /^(2|3)/
							fin err
			]
			done err
		it "should not allow a student to edit a thread that is not theirs", (done)->
			err <- async.waterfall [
				(cont)->
					student
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							cont err, res.body
				(tid,cont)->
					student
						.post "/cps1234/conference/#{tid.0._id.toString()}?hmo=put&action=editthread"
						.send {
							thread: tid.0._id.toString()
							title: "facultyThread"
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/cps1234\/conference\/?.{24}?\/?.{24}?\/?/
							cont err
			]
			done err
		it "should not allow a student to edit a post that is not theirs", (done)->
			err <- async.waterfall [
				(fin)->
					student
						.get "/test/getpost/cps1234?text=facultyPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					student
						.post "/cps1234/conference/#{tid.0.thread._id.toString()}/#{tid.0._id.toString()}?hmo=put&action=editpost"
						.send {
							thread: tid.0.thread._id.toString!
							post: tid.0._id.toString!
							text: "facultyPost"
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/cps1234\/conference\/?.{24}?\/?.{24}?\/?/
							fin err
			]
			done err
		it "should not allow a student to delete a thread that is not theirs", (done)->
			err <- async.waterfall [
				(cont)->
					student
						.get "/test/gettid/cps1234?title=facultyThread"
						.end (err, res)->
							cont err, res.body
				(tid,cont)->
					student
						.post "/cps1234/conference/#{tid.0._id.toString()}?hmo=delete&action=deletethread"
						.send {
							thread: tid.0._id.toString()
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/cps1234\/conference\/?.{24}?\/?.{24}?\/?/
							cont err
			]
			done err
		it "should not allow a student to delete a post that is not theirs", (done)->
			err <- async.waterfall [
				(fin)->
					student
						.get "/test/getpost/cps1234?text=facultyPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					student
						.post "/cps1234/conference/#{tid.0.thread._id.toString()}/#{tid.0._id.toString()}?hmo=delete&action=deletepost"
						.send {
							thread: tid.0.thread._id.toString!
							post: tid.0._id.toString!
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/cps1234\/conference\/?.{24}?\/?.{24}?\/?/
							fin err
			]
			done err
	describe "Outside Student", (...)->
		before (done)->
			err <- async.waterfall [
				(cont)->
					faculty
						.post "/cps1234/conference?action=newthread"
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
						.post "/cps1234/conference/#{tid.0._id.toString!}?action=newpost"
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
		it "should not allow an outside student to create a thread", (done)->
			student
				.post "/cps1234/conference?action=newthread"
				.send {
					title:"anything"
					text:"anything"
				}
				.end (err, res)->
					expect res.status .to.match /^(3|4|5)/
					expect res.header.location .to.not.match /^\/cps1234\/conference\/?.{24}?\/?.{24}?\/?/
					done err
		it "should not allow an outside student to edit a thread", (done)->
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
								.get "/cps1234/conference/#{tid.0._id.toString()}?action=editthread"
								.end (err, res)->
									expect res.status .to.match /^(3|4|5)/
									expect res.header.location .to.not.match /^\/cps1234\/conference\/?.{24}?\/?.{24}?\/?/
									fin err
						(fin)->
							student
								.post "/cps1234/conference/#{tid.0._id.toString()}?hmo=put&action=editthread"
								.send {
									thread: tid.0._id.toString()
									title: "studentThread"
								}
								.end (err, res)->
									expect res.status .to.match /^(3|4|5)/
									expect res.header.location .to.not.match /^\/cps1234\/conference\/?.{24}?\/?.{24}?\/?/
									fin err
					]
					cont err
			]
			done err
		it "should not allow an outside student to delete a thread", (done)->
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
								.get "/cps1234/conference/#{tid.0._id.toString()}?action=deletethread"
								.end (err, res)->
									expect res.status .to.match /^(3|4|5)/
									expect res.header.location .to.not.match /^\/cps1234\/conference\/?.{24}?\/?.{24}?\/?/
									fin err
						(fin)->
							student
								.post "/cps1234/conference/#{tid.0._id.toString()}?hmo=delete&action=deletethread"
								.send {
									thread: tid.0._id.toString()
								}
								.end (err, res)->
									expect res.status .to.match /^(3|4|5)/
									expect res.header.location .to.not.match /^\/cps1234\/conference\/?.{24}?\/?.{24}?\/?/
									fin err
					]
					cont err
			]
			done err
		it "should not allow an outside student to create a post", (done)->
			err <- async.waterfall [
				(fin)->
					student
						.get "/test/gettid/cps1234?title=adminThread"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					student
						.post "/cps1234/conference/#{tid.0._id.toString!}?action=newpost"
						.send {
							thread: tid.0._id.toString!
							text:"studentPost"
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/cps1234\/conference\/?.{24}?\/?.{24}?\/?/
							fin err
			]
			done err
		it "should not allow an outside student to edit a post", (done)->
			err <- async.waterfall [
				(fin)->
					student
						.get "/test/getpost/cps1234?text=facultyPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					student
						.post "/cps1234/conference/#{tid.0.thread._id.toString()}/#{tid.0._id.toString()}?hmo=put&action=editpost"
						.send {
							thread: tid.0.thread._id.toString!
							post: tid.0._id.toString!
							text: "facultyPost"
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/cps1234\/conference\/?.{24}?\/?.{24}?\/?/
							fin err
			]
			done err
		it "should not allow an outside student to delete a post", (done)->
			err <- async.waterfall [
				(fin)->
					student
						.get "/test/getpost/cps1234?text=facultyPost"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					student
						.post "/cps1234/conference/#{tid.0.thread._id.toString()}/#{tid.0._id.toString()}?hmo=delete&action=deletepost"
						.send {
							thread: tid.0.thread._id.toString!
							post: tid.0._id.toString!
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/cps1234\/conference\/?.{24}?\/?.{24}?\/?/
							fin err
			]
			done err
		it "should not allow an outside student to view thread list", (done)->
			student
				.get "/cps1234/conference"
				.end (err, res)->
					expect res.status .to.match /^(3|4|5)/
					expect res.header.location .to.not.match /^\/cps1234\/conference\/?.{24}?\/?.{24}?\/?/
					done err
		it "should not allow an outside student to view a thread", (done)->
			err <- async.waterfall [
				(fin)->
					student
						.get "/test/gettid/cps1234?title=adminThread"
						.end (err, res)->
							fin err, res.body
				(tid,fin)->
					student
						.get "/cps1234/conference/#{tid.0._id.toString()}"
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/cps1234\/conference\/?.{24}?\/?.{24}?\/?/
							fin err
			]
			done err
	describe "Other", (...)->
		it "should not allow creating a post after the thread is deleted", (done)->
			this.timeout = 4000
			err <- async.waterfall [
				(fin)->
					# create thread
					student
						.post "/cps1234/conference?action=newthread"
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
						.post "/cps1234/conference/#{tid.0._id.toString!}?hmo=delete&action=deletethread"
						.send {
							thread: tid.0._id.toString!
						}
						.end (err, res)->
							fin err, tid
				(tid,fin)->
					# try to post to thread
					student
						.post "/cps1234/conference/#{tid.0._id.toString!}?action=newpost"
						.send {
							thread: tid.0._id.toString!
							text: "deletedPost"
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4|5)/
							expect res.header.location .to.not.match /^\/cps1234\/conference\/?.{24}?\/?.{24}?\/?/
							expect res.text .to.not.have.string "deletedPost"
							fin err
			]
			done err