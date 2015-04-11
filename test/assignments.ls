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
describe "Assignments" ->
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
	describe "Faculty+", (...)->
		it "should allow a faculty to see the create assignment view", (done)->
			faculty
				.get "/cps1234/assignments?action=new"
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should allow an admin to see the create assignment view", (done)->
			admin
				.get "/cps1234/assignments?action=new"
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should allow a faculty to create an assignment", (done)->
			faculty
				.post "/cps1234/assignments?action=new"
				.send {
					"title":"title"
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
					expect res.status .to.equal 302
					expect res.header.location .to.match /^\/cps1234\/assignments\/.{24}\/?/i
					done err
		it "should allow an admin to create an assignment", (done)->
			admin
				.post "/cps1234/assignments?action=new"
				.send {
					"title":"anotherTitle"
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
					expect res.status .to.equal 302
					expect res.header.location .to.match /^\/cps1234\/assignments\/.{24}\/?/i
					done err
		it "should allow a faculty to view an assignment", (done)->
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
		it "should allow an admin to view an assignment", (done)->
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
		it "should allow a faculty to edit an assignment", (done)->
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
		it "should allow an admin to edit an assignment", (done)->
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
		it "should allow a faculty to delete an assignment", (done)->
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
		it "should allow an admin to delete an assignment", (done)->
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
		it "should allow a faculty to see the grades view", (done)->
			faculty
				.get "/cps1234/grades"
				.end (err, res)->
					expect res.status .to.match /200/
					done err
		it "should allow an admin to see the grades view", (done)->
			admin
				.get "/cps1234/grades"
				.end (err, res)->
					expect res.status .to.match /200/
					done err
	describe "Outside Faculty", (...)->
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
					expect res.header.location .to.match /^\/cps1234\/assignments\//i
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
		it "should not allow a faculty outside the course to create an assignment", (done)->
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
		it "should not allow a faculty outside the course to view an assignment", (done)->
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
		it "should not allow a faculty outside the course to edit an assignment", (done)->
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
		it "should not allow a faculty outside the course to delete an assignment", (done)->
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
		it "should not allow a faculty outside the course to see the grades view", (done)->
			faculty
				.get "/cps1234/grades"
				.end (err, res)->
					expect res.status .to.not.match /200/
					done err
	describe "Student", (...)->
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
					expect res.status .to.equal 302
					expect res.header.location .to.match /^\/cps1234\/assignments\//
					done err
		it "should not allow a student to create an assignment", (done)->
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
		it "should not allow a student to edit an assignment", (done)->
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
							"title": "title edited by a student"
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
		it "should not allow a student to delete an assignment", (done)->
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
							# expect res.status .to.not.equal 302
							expect res.header.location .to.not.match /\/cps1234\/assignments\/.{24}\/?/i
							cont err
			]
			done err
		it "should allow a student to view a list of assignments", (done)->
			student
				.get "/cps1234/assignments"
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should allow a student to view an assignment", (done)->
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
							expect res.status .to.equal 200
							cont err
			]
			done err
		it "should allow a student to submit an attempt on an assignment", (done)->
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
							expect res.status .to.not.match /^(4|5)/i
							expect res.headers.location .to.match /^\/cps1234\/assignments\/.{24}\/.{24}\/?/i
							cont err
			]
			done err
		it "should allow a student to see the grades view", (done)->
			student
				.get "/cps1234/grades"
				.end (err, res)->
					expect res.status .to.match /200/
					done err
	describe "Outside Student", (...)->
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
					expect res.text .to.have.string "Allowed assignment submission time has not opened."
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
					expect res.text .to.have.string "Allowed assignment submission time has closed."
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
		it "should give error for bad assignment length", (done)->
			student
				.get "/cps1234/assignments/1234"
				.end (err, res)->
					expect res.status .to.match /^(3|4|5)/
					done err
		it "should give error for bad attempt length", (done)->
			admin
				.get "/cps1234/assignments/123456789012345678901234/1234"
				.end (err, res)->
					expect res.status .to.match /^(3|4|5)/
					done err
		it "should give error for bad assignment", (done)->
			# this might succeed...fail in edge cases
			admin
				.get "/cps1234/assignments/123456789012345678901234"
				.end (err, res)->
					expect res.status .to.match /^(3|4|5)/
					done err
		it "should give error for bad attempt", (done)->
			# this might succeed...fail in edge cases
			admin
				.get "/cps1234/assignments/123456789012345678901234/123456789012345678901234"
				.end (err, res)->
					expect res.status .to.match /^(3|4|5)/
					done err
