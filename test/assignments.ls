require! {
	'async'
	'chai' # assert lib
	'del' # delete
	'lodash'
	'moment'
	'mongoose'
	'supertest' # request lib
}
app = require '../lib/app'
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
describe "Assignments" ->
	describe "Faculty+", (...)->
		before (done)->
			student
				.post '/login'
				.send {
					'username': 'student'
					'password': 'password'
				}
				.end (err, res)->
					expect res.status .to.equal 302
					done err
		before (done)->
			faculty
				.post '/login'
				.send {
					'username':'faculty'
					'password':'password'
				}
				.end (err, res)->
					expect res.status .to.equal 302
					done!
		before (done)->
			admin
				.post '/login'
				.send {
					'username':'admin'
					'password':'password'
				}
				.end (err, res)->
					expect res.status .to.equal 302
					done!
		it "should allow a faculty+ to create an assignment", (done)->
			faculty
				.post '/cps1234/assignments?action=new'
				.send {
					'title':'title'
					'opendate':'12/31/1999'
					'opentime':'1:00 AM'
					'closedate':'1/1/2000'
					'closetime':'1:00 PM'
					'total':'100'
					'tries':'1'
					'late':'yes'
					'text':'you will fail!'
				}
				.end (err, res)->
					expect res.status .to.equal 302
					expect res.header.location .to.equal '/cps1234/assignments/title'
					done err
		it "should allow an admin to create an assignment", (done)->
			admin
				.post '/cps1234/assignments?action=new'
				.send {
					'title':'anotherTitle'
					'opendate':'12/31/1999'
					'opentime':'1:00 AM'
					'closedate':'1/1/2000'
					'closetime':'1:00 PM'
					'total':'100'
					'tries':'1'
					'late':'yes'
					'text':'you will fail!'
				}
				.end (err, res)->
					expect res.status .to.equal 302
					expect res.header.location .to.equal '/cps1234/assignments/anotherTitle'
					done err
		it "should allow a faculty to view an assignment", (done)->
			faculty
				.get '/cps1234/assignments/title'
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should allow an admin to view an assignment", (done)->
			admin
				.get '/cps1234/assignments/anotherTitle'
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should allow a faculty to edit an assignment", (done)->
			err <- async.waterfall [
				(cont)->
					faculty
						.get '/test/getaid/cps1234?title=title'
						.end (err, res)->
							cont err, res.body
				(aid, cont)->
					faculty
						.post '/cps1234/assignments/title?hmo=PUT&action=edit'
						.send {
							'aid': ObjectId aid.0._id
							'title': decodeURIComponent aid.0.title
							'opendate': '12/31/1999'
							'opentime': '1:00 AM'
							'closedate': '1/1/2000'
							'closetime': '1:00 PM'
							'total': '100'
							'tries': '1'
							'late': 'yes'
							'text': 'you will fail!'
						}
						.end (err, res)->
							expect res.status .to.equal 302
							expect res.header.location .to.equal '/cps1234/assignments/'+ encodeURIComponent aid.0.title
							cont err
			]
			done err
		it "should allow an admin to edit an assignment", (done)->
			err <- async.waterfall [
				(cont)->
					admin
						.get '/test/getaid/cps1234?title=anotherTitle'
						.end (err, res)->
							cont err, res.body
				(aid, cont)->
					admin
						.post '/cps1234/assignments/anotherTitle?hmo=PUT&action=edit'
						.send {
							'aid': ObjectId aid.0._id
							'title': decodeURIComponent aid.0.title
							'opendate': '12/31/1999'
							'opentime': '1:00 AM'
							'closedate': '1/1/2000'
							'closetime': '1:00 PM'
							'total': '100'
							'tries': '1'
							'late': 'yes'
							'text': 'you will fail!'
						}
						.end (err, res)->
							expect res.status .to.equal 302
							expect res.header.location .to.equal '/cps1234/assignments/'+ aid.0.title
							cont err
			]
			done err
		it "should allow a faculty to delete an assignment", (done)->
			err <- async.waterfall [
				(cont)->
					faculty
						.get '/test/getaid/cps1234?title=title'
						.end (err, res)->
							cont err, res.body
				(aid,cont)->
					faculty
						.post '/cps1234/assignments/title?hmo=DELETE&action=delete'
						.send {
							'aid':aid.0._id
						}
						.end (err, res)->
							expect res.status .to.equal 302
							cont err
			]
			done err
		it "should allow an admin to delete an assignment", (done)->
			err <- async.waterfall [
				(cont)->
					admin
						.get '/test/getaid/cps1234?title=anotherTitle'
						.end (err, res)->
							cont err, res.body
				(aid,cont)->
					admin
						.post '/cps1234/assignments/anotherTitle?hmo=DELETE&action=delete'
						.send {
							'aid':aid.0._id
						}
						.end (err, res)->
							expect res.status .to.equal 302
							cont err
			]
			done err
	describe "Outside Faculty", (...)->
		it.skip "should not allow a faculty outside the course to create an assignment", (done)->
		it.skip "should not allow a faculty outside the course to view an assignment", (done)->
		it.skip "should not allow a faculty outside the course to edit an assignment", (done)->
		it.skip "should not allow a faculty outside the course to delete an assignment", (done)->
	describe "Student", (...)->
		before (done)->
			faculty
				.post '/cps1234/assignments?action=new'
				.send {
					'title':'title'
					'opendate':'12/31/1999'
					'opentime':'1:00 AM'
					'closedate':'1/1/2000'
					'closetime':'1:00 PM'
					'total':'100'
					'tries':'1'
					'late':'yes'
					'text':'you will fail!'
				}
				.end (err, res)->
					expect res.status .to.equal 302
					expect res.header.location .to.equal '/cps1234/assignments/title'
					done err
		it "should not allow a student to create an assignment", (done)->
			student
				.post '/cps1234/assignments?action=new'
				.send {
					'title':'title'
					'opendate':'12/31/1999'
					'opentime':'1:00 AM'
					'closedate':'1/1/2000'
					'closetime':'1:00 PM'
					'total':'100'
					'tries':'1'
					'late':'yes'
					'text':'you will fail!'
				}
				.end (err, res)->
					expect res.status .to.equal 302
					expect res.header.location .to.not.equal '/cps1234/assignments/title'
					done err
		it "should not allow a student to edit an assignment", (done)->
			err <- async.waterfall [
				(cont)->
					student
						.get '/test/getaid/cps1234?title=title'
						.end (err, res)->
							cont err, res.body
				(aid, cont)->
					student
						.post '/cps1234/assignments/title?hmo=PUT&action=edit'
						.send {
							'aid': ObjectId aid.0._id
							'title': decodeURIComponent aid.0.title
							'opendate': '12/31/1999'
							'opentime': '1:00 AM'
							'closedate': '1/1/2000'
							'closetime': '1:00 PM'
							'total': '100'
							'tries': '1'
							'late': 'yes'
							'text': 'you will fail!'
						}
						.end (err, res)->
							expect res.status .to.equal 302
							expect res.header.location .to.not.equal '/cps1234/assignments/'+ aid.0.title
							cont err
			]
			done err
		it "should not allow a student to delete an assignment", (done)->
			err <- async.waterfall [
				(cont)->
					admin
						.get '/test/getaid/cps1234?title=title'
						.end (err, res)->
							cont err, res.body
				(aid,cont)->
					admin
						.post '/cps1234/assignments/title?hmo=DELETE&action=delete'
						.send {
							'aid':aid.0._id
						}
						.end (err, res)->
							expect res.status .to.equal 302
							cont err
			]
			done err
		it "should allow a student to view a list of assignments", (done)->
			student
				.get '/cps1234/assignments'
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should allow a student to view an assignment", (done)->
			student
				.get '/cps1234/assignments/title'
				.end (err, res)->
					expect res.status .to.equal 200
					done err
	describe "Outside Student", (...)->
		before (done)->
			faculty
				.post '/cps1234/assignments?action=new'
				.send {
					'title':'title'
					'opendate':'12/31/1999'
					'opentime':'1:00 AM'
					'closedate':'1/1/2000'
					'closetime':'1:00 PM'
					'total':'100'
					'tries':'1'
					'late':'yes'
					'text':'you will fail!'
				}
				.end (err, res)->
					expect res.status .to.equal 302
					expect res.header.location .to.equal '/cps1234/assignments/title'
					done err
		before (done)->
			student
				.get '/logout'
				.end (err, res)->
					done err
		before (done)->
			student
				.post '/login'
				.send {
					'username': 'astudent'
					'password': 'password'
				}
				.end (err, res)->
					expect res.status .to.equal 302
					done err
		it "should not allow an outside student to create an assignment", (done)->
			student
				.post '/cps1234/assignments?action=new'
				.send {
					'title':'title'
					'opendate':'12/31/1999'
					'opentime':'1:00 AM'
					'closedate':'1/1/2000'
					'closetime':'1:00 PM'
					'total':'100'
					'tries':'1'
					'late':'yes'
					'text':'you will fail!'
				}
				.end (err, res)->
					expect res.status .to.equal 302
					expect res.header.location .to.equal '/'
					done err
		it "should not allow an outside student to edit an assignment", (done)->
			err <- async.waterfall [
				(cont)->
					student
						.get '/test/getaid/cps1234?title=title'
						.end (err, res)->
							cont err, res.body
				(aid, cont)->
					student
						.post '/cps1234/assignments/title?hmo=PUT&action=edit'
						.send {
							'aid': ObjectId aid.0._id
							'title': decodeURIComponent aid.0.title
							'opendate': '12/31/1999'
							'opentime': '1:00 AM'
							'closedate': '1/1/2000'
							'closetime': '1:00 PM'
							'total': '100'
							'tries': '1'
							'late': 'yes'
							'text': 'you will fail!'
						}
						.end (err, res)->
							expect res.status .to.equal 302
							expect res.header.location .to.equal '/'
							cont err
			]
			done err
		it "should not allow an outside student to delete an assignment", (done)->
			err <- async.waterfall [
				(cont)->
					student
						.get '/test/getaid/cps1234?title=title'
						.end (err, res)->
							cont err, res.body
				(aid,cont)->
					student
						.post '/cps1234/assignments/title?hmo=DELETE&action=delete'
						.send {
							'aid':aid.0._id
						}
						.end (err, res)->
							expect res.status .to.equal 302
							expect res.header.location .to.equal '/'
							cont err
			]
			done err
		it "should not allow an outside student to view a list of assignments", (done)->
			student
				.get '/cps1234/assignments'
				.end (err, res)->
					expect res.status .to.equal 302
					expect res.header.location .to.equal '/'
					done err
		it "should not allow an outside student to view an assignment", (done)->
			student
				.get '/cps1234/assignments/title'
				.end (err, res)->
					expect res.status .to.equal 302
					expect res.header.location .to.equal '/'
					done err
	describe "Crash Checks", (...)->
		it.skip "should not crash when creating/editing an assignment without opendate", (done)->
		it.skip "should not crash when creating/editing an assignment without opentime", (done)->
		it.skip "should not crash when creating/editing an assignment without opendate & opentime", (done)->
		it.skip "should not crash when creating/editing an assignment without closedate", (done)->
		it.skip "should not crash when creating/editing an assignment without closetime", (done)->
		it.skip "should not crash when creating/editing an assignment without closedate & closetime", (done)->
		it.skip "should not crash when creating/editing an assignment without points", (done)->
		it.skip "should not allow creating/editing an assignment without a title", (done)->
		it.skip "should not allow creating/editing an assignment without a body", (done)->
		it.skip "should not allow creating/editing an assignment without tries", (done)->
	describe "Other Functions", (...)->
		it.skip "should not allow late submissions if not allowed", (done)->
		it.skip "should allow late submissions if allowed", (done)->
		it.skip "should not allow more attempts than given", (done)->
	describe "Grade Book", (...)->
