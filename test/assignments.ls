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
var agent, student, faculty, admin, attemptid
assignid = []
outside = req.agent app
student = req.agent app
faculty = req.agent app
admin = req.agent app
describe "Assignments Module" ->
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
			.get "/test/deleteassignments/cps1234"
			.end (err,res)->
				done err
	describe "(User: Admin)", (...)->
		it "should return the create assignment view", (done)->
			admin
				.get "/cps1234/assignments?action=new"
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should create an assignment", (done)->
			admin
				.post "/cps1234/assignments?action=new"
				.send {
					"title":"anotherTitle"
					"opendate":"1/1/2000"
					"opentime":"1:00 AM"
					"closedate":"1/1/3000"
					"closetime":"1:00 PM"
					"total":"100"
					"tries":"1"
					"late":"yes"
					"text":"you will fail!"
				}
				.end (err, res)->
					expect res.status .to.equal 302
					expect res.header.location .to.match /^\/cps1234\/assignments\/.{24}\/?/i
					done err
		it "should return an assignment", (done)->
			err <- async.waterfall [
				(cont)->
					admin
						.get "/test/getaid/cps1234?title=anotherTitle"
						.end (err, res)->
							cont err, res.body
				(aid,cont)->
					admin
						.get "/cps1234/assignments/#{aid.0._id.toString()}"
						.end (err, res)->
							expect res.status .to.equal 200
							cont err
			]
			done err
		it "should edit an assignment", (done)->
			err <- async.waterfall [
				(cont)->
					admin
						.get "/test/getaid/cps1234?title=anotherTitle"
						.end (err, res)->
							cont err, res.body
				(aid, cont)->
					admin
						.post "/cps1234/assignments/#{aid.0._id.toString()}?hmo=PUT&action=edit"
						.send {
							"aid": aid.0._id
							"title": aid.0.title
							"opendate": "12/31/1999"
							"opentime": "1:00 AM"
							"closedate": "1/1/2000"
							"closetime": "1:00 PM"
							"total": "100"
							"tries": "1"
							"late": "yes"
							"text": "you will fail!"
						}
						.end (err, res)->
							expect res.status .to.equal 302
							expect res.header.location .to.match /^\/cps1234\/assignments\/.{24}\/?/i
							cont err
			]
			done err
		it "should submit an attempt", (done)->
			err <- async.waterfall [
				(cont)->
					admin
						.get "/test/getaid/cps1234?title=anotherTitle"
						.end (err, res)->
							cont err, res.body
				(aid,cont)->
					admin
						.post "/cps1234/assignments/#{aid.0._id.toString()}?action=attempt"
						.send {
							"aid":aid.0._id
							"text":"adminAttempt"
						}
						.end (err, res)->
							expect res.status .to.match /^(2|3)/
							expect res.header.location .to.match /^\/cps1234\/assignments\/.{24}\/.{24}\/?/i
							cont err
			]
			done err
		it "should grade an assignment", (done)->
			err <- async.waterfall [
				(cont)->
					admin
						.get "/test/getaid/cps1234?title=anotherTitle"
						.end (err, res)->
							cont err, res.body
				(assign,cont)->
					admin
						.get "/test/getattempt/cps1234?title=anotherTitle&text=adminAttempt"
						.end (err, res)->
							cont err, assign, res.body
				(assign,attempt,cont)->
					admin
						.post "/cps1234/assignments/#{assign.0._id.toString()}/#{attempt.0._id.toString()}?action=grade"
						.send {
							"aid":attempt.0._id
							"points": "10"
						}
						.end (err, res)->
							expect res.status .to.match /^(2|3)/
							expect res.header.location .to.match /^\/cps1234\/assignments\/.{24}\/.{24}\/?/i
							cont err
			]
			done err
		it "should delete an assignment", (done)->
			err <- async.waterfall [
				(cont)->
					admin
						.get "/test/getaid/cps1234?title=anotherTitle"
						.end (err, res)->
							cont err, res.body
				(aid,cont)->
					admin
						.post "/cps1234/assignments/#{aid.0._id.toString()}?hmo=DELETE&action=delete"
						.send {
							"aid":aid.0._id
						}
						.end (err, res)->
							expect res.status .to.equal 302
							expect res.header.location .to.match /^\/cps1234\/assignments\/?/i
							cont err
			]
			done err
		it "should see the grades view", (done)->
			admin
				.get "/cps1234/grades"
				.end (err, res)->
					expect res.status .to.match /200/
					done err

	describe "(User: Faculty)", (...)->
		it "should return the create assignment view", (done)->
			faculty
				.get "/cps1234/assignments?action=new"
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should create an assignment", (done)->
			faculty
				.post "/cps1234/assignments?action=new"
				.send {
					"title":"title"
					"opendate":"2/1/2000"
					"opentime":"1:00 AM"
					"closedate":"1/1/3000"
					"closetime":"1:00 PM"
					"total":"100"
					"tries":"1"
					"late":"yes"
					"text":"you will fail!"
				}
				.end (err, res)->
					expect res.status .to.equal 302
					expect res.header.location .to.match /^\/cps1234\/assignments\/.{24}\/?/i
					done err
		it "should return an assignment", (done)->
			err <- async.waterfall [
				(cont)->
					faculty
						.get "/test/getaid/cps1234?title=title"
						.end (err, res)->
							cont err, res.body
				(aid,cont)->
					faculty
						.get "/cps1234/assignments/#{aid.0._id.toString()}"
						.end (err, res)->
							expect res.status .to.equal 200
							cont err
			]
			done err
		it "should edit an assignment", (done)->
			err <- async.waterfall [
				(cont)->
					faculty
						.get "/test/getaid/cps1234?title=title"
						.end (err, res)->
							cont err, res.body
				(aid, cont)->
					faculty
						.post "/cps1234/assignments/#{aid.0._id.toString()}?hmo=PUT&action=edit"
						.send {
							"aid": aid.0._id
							"title": aid.0.title
							"opendate": "12/31/1999"
							"opentime": "1:00 AM"
							"closedate": "1/1/2000"
							"closetime": "1:00 PM"
							"total": "100"
							"tries": "1"
							"late": "yes"
							"text": "you will fail!"
						}
						.end (err, res)->
							expect res.status .to.equal 302
							expect res.header.location .to.match /^\/cps1234\/assignments\/.{24}\/?/i
							cont err
			]
			done err
		it "should submit an attempt", (done)->
			err <- async.waterfall [
				(cont)->
					faculty
						.get "/test/getaid/cps1234?title=title"
						.end (err, res)->
							cont err, res.body
				(aid,cont)->
					faculty
						.post "/cps1234/assignments/#{aid.0._id.toString()}?action=attempt"
						.send {
							"aid": aid.0._id
							"text":"facultyAttempt"
						}
						.end (err, res)->
							expect res.status .to.match /^(2|3)/
							expect res.header.location .to.match /^\/cps1234\/assignments\/.{24}\/.{24}\/?/i
							cont err
			]
			done err
		it "should grade an assignment", (done)->
			err <- async.waterfall [
				(cont)->
					faculty
						.get "/test/getaid/cps1234?title=title"
						.end (err, res)->
							cont err, res.body
				(assign,cont)->
					faculty
						.get "/test/getattempt/cps1234?title=title&text=facultyAttempt"
						.end (err, res)->
							cont err, assign, res.body
				(assign,attempt,cont)->
					faculty
						.post "/cps1234/assignments/#{assign.0._id.toString()}/#{attempt.0._id.toString()}?action=grade"
						.send {
							"aid": attempt.0._id
							"points": "10"
						}
						.end (err, res)->
							expect res.status .to.match /^(2|3)/
							expect res.header.location .to.match /^\/cps1234\/assignments\/.{24}\/.{24}\/?/i
							cont err
			]
			done err
		it "should delete an assignment", (done)->
			err <- async.waterfall [
				(cont)->
					faculty
						.get "/test/getaid/cps1234?title=title"
						.end (err, res)->
							cont err, res.body
				(aid,cont)->
					faculty
						.post "/cps1234/assignments/#{aid.0._id.toString()}?hmo=DELETE&action=delete"
						.send {
							"aid": aid.0._id
						}
						.end (err, res)->
							expect res.status .to.equal 302
							expect res.header.location .to.match /^\/cps1234\/assignments\/?/i
							cont err
			]
			done err
		it "should see the grades view", (done)->
			faculty
				.get "/cps1234/grades"
				.end (err, res)->
					expect res.status .to.match /200/
					done err

	describe "(User: Non-Faculty)", (done)->
		before (done)->
			faculty
				.post "/cps1234/assignments?action=new"
				.send {
					"title":"outsideFaculty"
					"opendate":"2/1/2000"
					"opentime":"1:00 AM"
					"closedate":"1/1/3000"
					"closetime":"1:00 PM"
					"total":"100"
					"tries":"100"
					"late":"yes"
					"text":"you will fail!"
				}
				.end (err, res)->
					expect res.status .to.equal 302
					expect res.header.location .to.match /^\/cps1234\/assignments\/?/i
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
			err <- async.waterfall [
				(cont)->
					faculty
						.get "/logout"
						.end (err, res)->
							cont err
				(cont)->
					faculty
						.post "/login"
						.send {
							"username": "faculty"
							"password": "password"
						}
						.end (err, res)->
							expect res.status .to.equal 302
							cont err
			]
			done err
		after (done)->
			# clean up outsideFaculty
			err <- async.waterfall [
				(cont)->
					admin
						.get "/test/getaid/cps1234?title=outsideFaculty"
						.end (err, res)->
							cont err, res.body
				(aid,cont)->
					admin
						.post "/cps1234/assignments/#{aid.0._id.toString()}?hmo=DELETE&action=delete"
						.send {
							"aid": aid.0._id
						}
						.end (err, res)->
							expect res.status .to.equal 302
							cont err
			]
			done err
		it "should not return the create assignment view", (done)->
			faculty
				.get "/cps1234/assignments?action=new"
				.end (err, res)->
					expect res.status .to.not.equal 200
					done err
		it "should not create an assignment", (done)->
			faculty
				.post "/cps1234/assignments?action=new"
				.send {
					"title":"created by outsideFaculty"
					"opendate":"12/31/1999"
					"opentime":"1:00 AM"
					"closedate":"1/1/2000"
					"closetime":"1:00 PM"
					"total":"100"
					"tries":"1"
					"late":"yes"
					"text":"you will fail!"
				}
				.end (err, res)->
					expect res.status .to.match /^(3|4)/
					expect res.header.location .to.not.equal /\/cps1234\/assignments\/.{24}\/?/i
					done err
		it "should not return an assignment", (done)->
			err <- async.waterfall [
				(cont)->
					admin
						.get "/test/getaid/cps1234?title=outsideFaculty"
						.end (err, res)->
							cont err, res.body
				(aid,cont)->
					faculty
						.get "/cps1234/assignments/#{aid.0._id.toString()}"
						.end (err, res)->
							expect res.status .to.not.equal 200
							cont err
			]
			done err
		it "should not edit an assignment", (done)->
			err <- async.waterfall [
				(cont)->
					faculty
						.get "/test/getaid/cps1234?title=outsideFaculty"
						.end (err, res)->
							cont err, res.body
				(aid, cont)->
					faculty
						.post "/cps1234/assignments/#{aid.0._id.toString()}?hmo=PUT&action=edit"
						.send {
							"aid": aid.0._id
							"title": aid.0.title
							"opendate": "12/31/1999"
							"opentime": "1:00 AM"
							"closedate": "1/1/2000"
							"closetime": "1:00 PM"
							"total": "100"
							"tries": "1"
							"late": "yes"
							"text": "you will fail!"
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4)/
							expect res.header.location .to.not.equal /\/cps1234\/assignments\/.{24}\/?/i
							cont err
			]
			done err
		it "should not submit an attempt", (done)->
			err <- async.waterfall [
				(cont)->
					faculty
						.get "/test/getaid/cps1234?title=outsideFaculty"
						.end (err, res)->
							cont err, res.body
				(aid,cont)->
					faculty
						.post "/cps1234/assignments/#{aid.0._id.toString()}?action=attempt"
						.send {
							"aid": aid.0._id
							"text":"facultyAttempt"
						}
						.expect 404
						.end (err, res)->
							expect res.header.location .to.not.match /^\/cps1234\/assignments\/.{24}\/.{24}\/?/i
							cont err
			]
			done err
		it "should not delete an assignment", (done)->
			err <- async.waterfall [
				(cont)->
					faculty
						.get "/test/getaid/cps1234?title=outsideFaculty"
						.end (err, res)->
							cont err, res.body
				(aid,cont)->
					faculty
						.post "/cps1234/assignments/#{aid.0._id.toString()}?hmo=DELETE&action=delete"
						.send {
							"aid":aid.0._id
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4)/
							expect res.header.location .to.not.match /\/cps1234\/assignments\/?/
							cont err
			]
			done err
		it "should not see the grades view", (done)->
			faculty
				.get "/cps1234/grades"
				.end (err, res)->
					expect res.status .to.not.match /200/
					done err

	describe "(User: Student)", (...)->
		before (done)->
			faculty
				.post "/cps1234/assignments?action=new"
				.send {
					"title":"student"
					"opendate":"2/1/2000"
					"opentime":"1:00 AM"
					"closedate":"1/1/3000"
					"closetime":"1:00 PM"
					"total":"100"
					"tries":"100"
					"late":"yes"
					"text":"you will fail!"
				}
				.end (err, res)->
					expect res.status .to.equal 302
					expect res.header.location .to.match /^\/cps1234\/assignments\/?/i
					done err
		it "should not create an assignment", (done)->
			student
				.post "/cps1234/assignments?action=new"
				.send {
					"title":"student created this"
					"opendate":"12/31/1999"
					"opentime":"1:00 AM"
					"closedate":"1/1/2000"
					"closetime":"1:00 PM"
					"total":"100"
					"tries":"1"
					"late":"yes"
					"text":"you will fail!"
				}
				.end (err, res)->
					# expect res.status .to.equal 302
					expect res.header.location .to.not.match /^\/cps1234\/assignments\/.{24}\/?/i
					done err
		it "should not edit an assignment", (done)->
			err <- async.waterfall [
				(cont)->
					student
						.get "/test/getaid/cps1234?title=student"
						.end (err, res)->
							cont err, res.body
				(aid, cont)->
					student
						.post "/cps1234/assignments/#{aid.0._id.toString()}?hmo=PUT&action=edit"
						.send {
							"aid": aid.0._id
							"title": "edited by a student"
							"opendate": "12/31/1999"
							"opentime": "1:00 AM"
							"closedate": "1/1/2000"
							"closetime": "1:00 PM"
							"total": "100"
							"tries": "100"
							"late": "yes"
							"text": "you will fail!"
						}
						.end (err, res)->
							# expect res.status .to.equal 302
							expect res.header.location .to.not.match /\/cps1234\/assignments\/.{24}\/?/i # #{aid.0._id.toString()}"
							cont err
			]
			done err
		it "should not delete an assignment", (done)->
			err <- async.waterfall [
				(cont)->
					student
						.get "/test/getaid/cps1234?title=student"
						.end (err, res)->
							cont err, res.body
				(aid,cont)->
					student
						.post "/cps1234/assignments/#{aid.0._id.toString()}?hmo=DELETE&action=delete"
						.send {
							"aid":aid.0._id
						}
						.end (err, res)->
							# expect res.status .to.not.equal 302
							expect res.header.location .to.not.match /\/cps1234\/assignments\/.{24}\/?/i
							cont err
			]
			done err
		it "should view a list of assignments", (done)->
			student
				.get "/cps1234/assignments"
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should view an assignment", (done)->
			err <- async.waterfall [
				(cont)->
					admin
						.get "/test/getaid/cps1234?title=student"
						.end (err, res)->
							cont err, res.body
				(aid,cont)->
					student
						.get "/cps1234/assignments/#{aid.0._id.toString()}"
						.end (err, res)->
							expect res.status .to.equal 200
							cont err
			]
			done err
		it "should submit an attempt on an assignment", (done)->
			err <- async.waterfall [
				(cont)->
					student
						.post "/test/getaid/cps1234?title=student"
						.end (err, res)->
							cont err, res.body
				(aid, cont)->
					student
						.post "/cps1234/assignments/#{aid.0._id.toString()}?action=attempt"
						.send {
							"aid":aid.0._id
							"text":"something right here"
						}
						.end (err, res)->
							expect res.status .to.not.match /^(4|5)/i
							expect res.header.location .to.match /^\/cps1234\/assignments\/.{24}\/.{24}\/?/i
							attemptid := res.header.location
							cont err
			]
			done err
		it "should view an attempt on an assignment", (done)->
			student
				.get attemptid
				.end (err, res)->
					done err, res.body
		it "should see the grades view", (done)->
			student
				.get "/cps1234/grades"
				.end (err, res)->
					expect res.status .to.match /200/
					done err
	describe "(User: Non-Student)", (...)->
		before (done)->
			faculty
				.post "/cps1234/assignments?action=new"
				.send {
					"title":"aUniqueTitle"
					"opendate":"2/1/2000"
					"opentime":"1:00 AM"
					"closedate":"1/1/3000"
					"closetime":"1:00 PM"
					"total":"100"
					"tries":"100"
					"late":"yes"
					"text":"you will fail!"
				}
				.end (err, res)->
					expect res.status .to.match /^(3|4)/
					expect res.header.location .to.match /^\/cps1234\/assignments\/.{24}\/?/
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
		it "should not allow an outside student to create an assignment", (done)->
			student
				.post "/cps1234/assignments?action=new"
				.send {
					"title":"aUniqueTitle"
					"opendate":"12/31/1999"
					"opentime":"1:00 AM"
					"closedate":"1/1/2000"
					"closetime":"1:00 PM"
					"total":"100"
					"tries":"1"
					"late":"yes"
					"text":"you will fail!"
				}
				.end (err, res)->
					expect res.status .to.match /^(3|4)/i
					expect res.header.location .to.not.match /\/cps1234\/assignments\/.{24}\/?/i
					done err
		it "should not allow an outside student to edit an assignment", (done)->
			err <- async.waterfall [
				(cont)->
					student
						.get "/test/getaid/cps1234?title=aUniqueTitle"
						.end (err, res)->
							cont err, res.body
				(aid, cont)->
					student
						.post "/cps1234/assignments/#{aid.0._id.toString()}?hmo=PUT&action=edit"
						.send {
							"aid": aid.0._id
							"title": "edited by an outside student"
							"opendate": "12/31/1999"
							"opentime": "1:00 AM"
							"closedate": "1/1/2000"
							"closetime": "1:00 PM"
							"total": "100"
							"tries": "1"
							"late": "yes"
							"text": "you will fail!"
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4)/i
							expect res.header.location .to.not.match /\/cps1234\/assignments\/.{24}\/?/i
							cont err
			]
			done err
		it "should not allow an outside student to delete an assignment", (done)->
			err <- async.waterfall [
				(cont)->
					student
						.get "/test/getaid/cps1234?title=aUniqueTitle"
						.end (err, res)->
							cont err, res.body
				(aid,cont)->
					student
						.post "/cps1234/assignments/#{aid.0._id.toString()}?hmo=DELETE&action=delete"
						.send {
							"aid":aid.0._id
						}
						.end (err, res)->
							expect res.status .to.match /^(3|4)/i
							expect res.header.location .to.not.match /\/cps1234\/assignments\/?/i
							cont err
			]
			done err
		it "should not allow an outside student to view a list of assignments", (done)->
			student
				.get "/cps1234/assignments"
				.end (err, res)->
					expect res.status .to.match /^(3|4)/i
					expect res.header.location .to.not.match /\/cps1234\/assignments\/?/i
					done err
		it "should not allow an outside student to view an assignment", (done)->
			err <- async.waterfall [
				(cont)->
					admin
						.get "/test/getaid/cps1234?title=aUniqueTitle"
						.end (err, res)->
							cont err, res.body
				(aid,cont)->
					student
						.get "/cps1234/assignments/#{aid.0._id.toString()}"
						.end (err, res)->
							expect res.status .to.match /^(3|4)/i
							expect res.header.location .to.not.match /\/cps1234\/assignments\/?.{24}?\/?/i
							cont err
			]
			done err
		it "should not allow an outside student to submit an attempt on an assignment", (done)->
			err <- async.waterfall [
				(cont)->
					student
						.post "/test/getaid/cps1234?title=aUniqueTitle"
						.end (err, res)->
							cont err, res.body
				(aid, cont)->
					student
						.post "/cps1234/assignments/#{aid.0._id.toString()}?action=attempt"
						.send {
							"aid":aid.0._id
							"text":"something right here"
						}
						.end (err, res)->
							expect res.headers.location .to.not.match /\/cps1234\/assignments\/.{24}?\/?.{24}?\/?/i
							cont err
			]
			done err
		it "should not allow an outside student to see the grades view", (done)->
			student
				.get "/cps1234/grades"
				.end (err, res)->
					expect res.status .to.not.match /200/
					done err
	describe "Crash Checks", (...)->
		it "should not crash when creating/editing an assignment without opendate", (done)->
			faculty
				.post "/cps1234/assignments?action=new"
				.send {
					"title":"title"
					"opentime":"1:00 AM"
					"closedate":"1/1/2000"
					"closetime":"1:00 PM"
					"total":"100"
					"tries":"1"
					"late":"yes"
					"text":"you will fail!"
				}
				.end (err, res)->
					expect res.status .to.not.match /^(4|5)/i
					expect res.header.location .to.match /^\/cps1234\/assignments\/.{24}\/?/i
					done err
		it "should not crash when creating/editing an assignment without opentime", (done)->
			faculty
				.post "/cps1234/assignments?action=new"
				.send {
					"title":"title"
					"opendate":"12/31/1999"
					"closedate":"1/1/2000"
					"closetime":"1:00 PM"
					"total":"100"
					"tries":"1"
					"late":"yes"
					"text":"you will fail!"
				}
				.end (err, res)->
					expect res.status .to.not.match /^(4|5)/i
					expect res.header.location .to.match /^\/cps1234\/assignments\/.{24}\/?/i
					done err
		it "should not crash when creating/editing an assignment without opendate & opentime", (done)->
			faculty
				.post "/cps1234/assignments?action=new"
				.send {
					"title":"title"
					"closedate":"1/1/2000"
					"closetime":"1:00 PM"
					"total":"100"
					"tries":"1"
					"late":"yes"
					"text":"you will fail!"
				}
				.end (err, res)->
					expect res.status .to.not.match /^(4|5)/i
					expect res.header.location .to.match /^\/cps1234\/assignments\/.{24}\/?/i
					done err
		it "should not crash when creating/editing an assignment without closedate", (done)->
			faculty
				.post "/cps1234/assignments?action=new"
				.send {
					"title":"title"
					"opendate":"12/31/1999"
					"opentime":"1:00 AM"
					"closetime":"1:00 PM"
					"total":"100"
					"tries":"1"
					"late":"yes"
					"text":"you will fail!"
				}
				.end (err, res)->
					expect res.status .to.not.match /^(4|5)/i
					expect res.header.location .to.match /^\/cps1234\/assignments\/.{24}\/?/i
					done err
		it "should not crash when creating/editing an assignment without closetime", (done)->
			faculty
				.post "/cps1234/assignments?action=new"
				.send {
					"title":"title"
					"opendate":"12/31/1999"
					"opentime":"1:00 AM"
					"closedate":"1/1/2000"
					"total":"100"
					"tries":"1"
					"late":"yes"
					"text":"you will fail!"
				}
				.end (err, res)->
					expect res.status .to.not.match /^(4|5)/i
					expect res.header.location .to.match /^\/cps1234\/assignments\/.{24}\/?/i
					done err
		it "should not crash when creating/editing an assignment without closedate & closetime", (done)->
			faculty
				.post "/cps1234/assignments?action=new"
				.send {
					"title":"title"
					"opendate":"12/31/1999"
					"opentime":"1:00 AM"
					"total":"100"
					"tries":"1"
					"late":"yes"
					"text":"you will fail!"
				}
				.end (err, res)->
					expect res.status .to.not.match /^(4|5)/i
					expect res.header.location .to.match /^\/cps1234\/assignments\/.{24}\/?/i
					done err
		it "should not crash when creating/editing an assignment without points", (done)->
			faculty
				.post "/cps1234/assignments?action=new"
				.send {
					"title":"title"
					"opendate":"12/31/1999"
					"opentime":"1:00 AM"
					"closedate":"1/1/2000"
					"closetime":"1:00 PM"
					"tries":"1"
					"late":"yes"
					"text":"you will fail!"
				}
				.end (err, res)->
					expect res.status .to.not.match /^(4|5)/i
					expect res.header.location .to.match /^\/cps1234\/assignments\/.{24}\/?/i
					done err
		it "should not allow creating/editing an assignment without a title", (done)->
			faculty
				.post "/cps1234/assignments?action=new"
				.send {
					"opendate":"12/31/1999"
					"opentime":"1:00 AM"
					"closedate":"1/1/2000"
					"closetime":"1:00 PM"
					"tries":"1"
					"late":"yes"
					"text":"you will fail!"
				}
				.end (err, res)->
					# expect res.status .to.not.match /^(4|5)/i
					expect res.header.location .to.not.match /^\/cps1234\/assignments\/.{24}\/?/i
					done err
		it "should not allow creating/editing an assignment without a body", (done)->
			faculty
				.post "/cps1234/assignments?action=new"
				.send {
					"title":"title"
					"opendate":"12/31/1999"
					"opentime":"1:00 AM"
					"closedate":"1/1/2000"
					"closetime":"1:00 PM"
					"tries":"1"
					"late":"yes"
				}
				.end (err, res)->
					# expect res.status .to.not.match /^(4|5)/i
					expect res.header.location .to.not.match /^\/cps1234\/assignments\/.{24}\/?/i
					done err
		it "should not allow creating/editing an assignment without tries", (done)->
			faculty
				.post "/cps1234/assignments?action=new"
				.send {
					"title":"title"
					"opendate":"12/31/1999"
					"opentime":"1:00 AM"
					"closedate":"1/1/2000"
					"closetime":"1:00 PM"
					"late":"yes"
					"text":"you will fail!"
				}
				.end (err, res)->
					# expect res.status .to.not.match /^(4|5)/i
					expect res.header.location .to.not.match /^\/cps1234\/assignments\/.{24}\/?/i
					done err
	describe "Other Functions", (...)->
		otherFunc = {}
		before (done)->
			err <- async.waterfall [
				(cont)->
					student
						.get "/logout"
						.end (err, res)->
							cont err
				(cont)->
					student
						.post "/login"
						.send {
							"username": "student"
							"password": "password"
						}
						.end (err, res)->
							expect res.status .to.equal 302
							cont err
			]
			done err
		before (done)->
			# for now < date
			faculty
				.post "/cps1234/assignments?action=new"
				.send {
					"title":"Early"
					"opendate":"1/1/3000"
					"opentime":"1:00 AM"
					"closedate":"1/1/4000"
					"closetime":"1:00 PM"
					"total":"100"
					"tries":"100"
					"late":"yes"
					"text":"you will fail!"
				}
				.end (err, res)->
					expect res.status .to.not.match /^(4|5)/i
					done err
		before (done)->
			# for now > close
			faculty
				.post "/cps1234/assignments?action=new"
				.send {
					"title":"Late"
					"opendate":"1/1/1000"
					"opentime":"1:00 AM"
					"closedate":"1/1/2000"
					"closetime":"1:00 PM"
					"total":"100"
					"tries":"100"
					"late":"no"
					"text":"you will fail!"
				}
				.end (err, res)->
					expect res.status .to.not.match /^(4|5)/i
					done err
		before (done)->
			# for now > close & allowLate = true
			faculty
				.post "/cps1234/assignments?action=new"
				.send {
					"title":"allowLate"
					"opendate":"1/1/1000"
					"opentime":"1:00 AM"
					"closedate":"1/1/2000"
					"closetime":"1:00 PM"
					"total":"100"
					"tries":"1000"
					"late":"yes"
					"text":"you will fail!"
				}
				.end (err, res)->
					expect res.status .to.not.match /^(4|5)/i
					done err
		before (done)->
			# for attempts > allowed
			faculty
				.post "/cps1234/assignments?action=new"
				.send {
					"title":"None"
					"opendate":"1/1/2000"
					"opentime":"1:00 AM"
					"closedate":"1/1/3000"
					"closetime":"1:00 PM"
					"total":"100"
					"tries":"0"
					"late":"yes"
					"text":"you will fail!"
				}
				.end (err, res)->
					expect res.status .to.not.match /^(4|5)/i
					done err
		before (done)->
			err <- async.parallel [
				(cont)->
					student
						.post "/test/getaid/cps1234?title=Early"
						.end (err, res)->
							assignments = JSON.parse res.text
							otherFunc.Early = assignments.0._id
							cont err
				(cont)->
					student
						.post "/test/getaid/cps1234?title=Late"
						.end (err, res)->
							assignments = JSON.parse res.text
							otherFunc.Late = assignments.0._id
							cont err
				(cont)->
					student
						.post "/test/getaid/cps1234?title=allowLate"
						.end (err, res)->
							assignments = JSON.parse res.text
							otherFunc.allowLate = assignments.0._id
							cont err
				(cont)->
					student
						.post "/test/getaid/cps1234?title=None"
						.end (err, res)->
							assignments = JSON.parse res.text
							otherFunc.None = assignments.0._id
							cont err
			]
			done err
		after (done)->
			this.timeout 0
			# clean up outsideFaculty
			admin
				.get "/test/deleteassignments/cps1234"
				.end (err, res)->
					done err
		it "should not allow early submissions", (done)->
			student
				.post "/cps1234/assignments/#{otherFunc.Early}?action=attempt"
				.send {
					"aid":otherFunc.Early
					"text":"something"
				}
				.end (err, res)->
					expect res.status .to.equal 400
					expect res.text .to.have.string "Allowed assignment submission window has not opened."
					done err
		it "should not allow late submissions if not allowed", (done)->
			student
				.post "/cps1234/assignments/#{otherFunc.Late}?action=attempt"
				.send {
					"aid":otherFunc.Late
					"text":"something"
				}
				.end (err, res)->
					expect res.status .to.equal 400
					expect res.text .to.have.string "Allowed assignment submission window has closed."
					done err
		it "should allow late submissions if allowed", (done)->
			student
				.post "/cps1234/assignments/#{otherFunc.allowLate}?action=attempt"
				.send {
					"aid":otherFunc.allowLate
					"text":"something"
				}
				.end (err, res)->
					expect res.status .to.not.match /^(4|5)/i
					done err
		it "should not allow more attempts than given", (done)->
			student
				.post "/cps1234/assignments/#{otherFunc.None}?action=attempt"
				.send {
					"aid":otherFunc.None
					"text":"something"
				}
				.end (err, res)->
					expect res.status .to.equal 400
					expect res.text .to.have.string "You have no more attempts."
					done err
	describe "Other", (...)->
		it "should give an error for bad assignment length", (done)->
			student
				.get "/cps1234/assignments/1234"
				.end (err, res)->
					expect res.status .to.match /^(3|4|5)/
					done err
		it "should give an error for bad attempt length", (done)->
			admin
				.get "/cps1234/assignments/123456789012345678901234/1234"
				.end (err, res)->
					expect res.status .to.match /^(3|4|5)/
					done err
		it "should give an error for a bad assignment", (done)->
			# this might succeed...fail in edge cases
			admin
				.get "/cps1234/assignments/123456789012345678901234"
				.end (err, res)->
					expect res.status .to.match /^(3|4|5)/
					done err
		it "should give an error for a bad attempt", (done)->
			# this might succeed...fail in edge cases
			admin
				.get "/cps1234/assignments/123456789012345678901234/123456789012345678901234"
				.end (err, res)->
					expect res.status .to.match /^(3|4|5)/
					done err
		it "should give an error for attempting to post with different action", (done)->
			admin
				.post "/cps1234/assignments?action=anything"
				.send {}
				.end (err, res)->
					expect res.status .to.match /^(3|4|5)/
					done err
		it "should give an error for attempting to put with different action", (done)->
			admin
				.put "/cps1234/assignments?hmo=put&action=anything"
				.send {}
				.end (err, res)->
					expect res.status .to.match /^(3|4|5)/
					done err
		it "should give an error for attempting to delete with different action", (done)->
			admin
				.delete "/cps1234/assignments?action=anything"
				.send {}
				.end (err, res)->
					expect res.status .to.match /^(3|4|5)/
					done err
