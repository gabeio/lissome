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
var agent, student, faculty, admin, courseId, attemptid
assignid = []
outside = req.agent app
student = req.agent app
faculty = req.agent app
admin = req.agent app
describe "Assignments Module" !->
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
						expect res.status .to.equal 302
						next err
			(next)!->
				faculty
					.post "/login"
					.send {
						"username":"faculty"
						"password":"password"
					}
					.end (err, res)!->
						expect res.status .to.equal 302
						next err
			(next)!->
				admin
					.post "/login"
					.send {
						"username":"admin"
						"password":"password"
					}
					.end (err, res)!->
						expect res.status .to.equal 302
						next err
		]
		done err
	after (done)!->
		this.timeout = 0
		admin
			.get "/test/deleteassignments/cps1234"
			.end (err,res)!->
				done err
	describe "(User: Admin)", (...)!->
		it "should return the assignment default view", (done)!->
			admin
				.get "/c/#{courseId}/assignments"
				.end (err, res)!->
					expect res.status .to.equal 200
					done err
		it "should return the create assignment view", (done)!->
			admin
				.get "/c/#{courseId}/assignments/new"
				.end (err, res)!->
					expect res.status .to.equal 200
					done err
		it "should create an assignment", (done)!->
			admin
				.post "/c/#{courseId}/assignments/new"
				.send {
					"title":"admin"
					"opendate":"1/1/2000"
					"opentime":"1:00 AM"
					"closedate":"1/1/3000"
					"closetime":"1:00 PM"
					"total":"100"
					"tries":"1"
					"late":"yes"
					"text":"you will fail!"
				}
				.expect 302
				.end (err, res)!->
					expect res.header.location .to.match /^\/c\/.{24}\/assignment\/.{24}\/?/i
					done err
		it "should not create an assignment without a title", (done)!->
			admin
				.post "/c/#{courseId}/assignments/new"
				.send {
					"title":""
					"opendate":"1/1/2000"
					"opentime":"1:00 AM"
					"closedate":"1/1/3000"
					"closetime":"1:00 PM"
					"total":"100"
					"tries":"1"
					"late":"yes"
					"text":"you will fail!"
				}
				.expect 400
				.end (err, res)!->
					done err
		it "should return an assignment", (done)!->
			err <- async.waterfall [
				(cont)!->
					admin
						.get "/test/getaid/cps1234?title=admin"
						.end (err, res)!->
							cont err, res.body
				(aid,cont)!->
					admin
						.get "/c/#{courseId}/assignment/#{aid.0._id.toString()}"
						.end (err, res)!->
							expect res.status .to.equal 200
							cont err
			]
			done err
		it "should return the edit assignment view", (done)!->
			err <- async.waterfall [
				(cont)!->
					admin
						.get "/test/getaid/cps1234?title=admin"
						.end (err, res)!->
							cont err, res.body
				(aid,cont)!->
					admin
						.get "/c/#{courseId}/assignment/#{aid.0._id}/edit"
						.end (err, res)!->
							expect res.status .to.equal 200
							cont err
			]
			done err
		it "should edit an assignment", (done)!->
			err <- async.waterfall [
				(cont)!->
					admin
						.get "/test/getaid/cps1234?title=admin"
						.end (err, res)!->
							cont err, res.body
				(aid, cont)!->
					admin
						.post "/c/#{courseId}/assignment/#{aid.0._id.toString()}/edit?hmo=PUT"
						.send {
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
						.end (err, res)!->
							expect res.status .to.equal 302
							expect res.header.location .to.match /^\/c\/.{24}\/assignment\/.{24}\/?/i
							cont err
			]
			done err
		it "should edit an assignment and remove total with total blank", (done)!->
			err <- async.waterfall [
				(cont)!->
					admin
						.get "/test/getaid/cps1234?title=admin"
						.end (err, res)!->
							cont err, res.body
				(aid, cont)!->
					admin
						.post "/c/#{courseId}/assignment/#{aid.0._id.toString()}/edit?hmo=PUT"
						.send {
							"title": aid.0.title
							"opendate": "12/31/1999"
							"opentime": "1:00 AM"
							"closedate": "1/1/2000"
							"closetime": "1:00 PM"
							"total": ""
							"tries": "1"
							"late": "yes"
							"text": "you will fail!"
						}
						.end (err, res)!->
							expect res.status .to.equal 302
							expect res.header.location .to.match /^\/c\/.{24}\/assignment\/.{24}\/?/i
							cont err
			]
			done err
		it "should edit an assignment and remove total with total undefined", (done)!->
			err <- async.waterfall [
				(cont)!->
					admin
						.get "/test/getaid/cps1234?title=admin"
						.end (err, res)!->
							cont err, res.body
				(aid, cont)!->
					admin
						.post "/c/#{courseId}/assignment/#{aid.0._id.toString()}/edit?hmo=PUT"
						.send {
							"title": aid.0.title
							"opendate": "12/31/1999"
							"opentime": "1:00 AM"
							"closedate": "1/1/2000"
							"closetime": "1:00 PM"
							"tries": "1"
							"late": "yes"
							"text": "you will fail!"
						}
						.end (err, res)!->
							expect res.status .to.equal 302
							expect res.header.location .to.match /^\/c\/.{24}\/assignment\/.{24}\/?/i
							cont err
			]
			done err
		it "should edit an assignment and remove open date/open time", (done)!->
			err <- async.waterfall [
				(cont)!->
					admin
						.get "/test/getaid/cps1234?title=admin"
						.end (err, res)!->
							cont err, res.body
				(aid, cont)!->
					admin
						.post "/c/#{courseId}/assignment/#{aid.0._id.toString()}/edit?hmo=PUT"
						.send {
							"title": aid.0.title
							"opendate": ""
							"opentime": ""
							"closedate": "1/1/2000"
							"closetime": "1:00 PM"
							"total": ""
							"tries": "1"
							"late": "yes"
							"text": "you will fail!"
						}
						.end (err, res)!->
							expect res.status .to.equal 302
							expect res.header.location .to.match /^\/c\/.{24}\/assignment\/.{24}\/?/i
							cont err
			]
			done err
		it "should edit an assignment and remove close date/close time", (done)!->
			err <- async.waterfall [
				(cont)!->
					admin
						.get "/test/getaid/cps1234?title=admin"
						.end (err, res)!->
							cont err, res.body
				(aid, cont)!->
					admin
						.post "/c/#{courseId}/assignment/#{aid.0._id.toString()}/edit?hmo=PUT"
						.send {
							"title": aid.0.title
							"opendate": "12/31/1999"
							"opentime": "1:00 AM"
							"closedate": ""
							"closetime": ""
							"total": "100"
							"tries": "1"
							"late": "yes"
							"text": "you will fail!"
						}
						.end (err, res)!->
							expect res.status .to.equal 302
							expect res.header.location .to.match /^\/c\/.{24}\/assignment\/.{24}\/?/i
							cont err
			]
			done err
		it "should edit an assignment and remove close date/close time with rediculously bad close date/time", (done)!->
			err <- async.waterfall [
				(cont)!->
					admin
						.get "/test/getaid/cps1234?title=admin"
						.end (err, res)!->
							cont err, res.body
				(aid, cont)!->
					admin
						.post "/c/#{courseId}/assignment/#{aid.0._id.toString()}/edit?hmo=PUT"
						.send {
							"title": aid.0.title
							"opendate": "12/31/1999"
							"opentime": "1:00 AM"
							"closedate": "13/45/1"
							"closetime": "32:00 AM"
							"total": "100"
							"tries": "1"
							"late": "no"
							"text": "you will fail!"
						}
						.end (err, res)!->
							expect res.status .to.equal 302
							expect res.header.location .to.match /^\/c\/.{24}\/assignment\/.{24}\/?/i
							cont err
			]
			done err
		it "should not edit an assignment to remove a title", (done)!->
			err <- async.waterfall [
				(cont)!->
					admin
						.get "/test/getaid/cps1234?title=admin"
						.end (err, res)!->
							cont err, res.body
				(aid, cont)!->
					admin
						.post "/c/#{courseId}/assignment/#{aid.0._id.toString()}/edit?hmo=PUT"
						.send {
							"title": ""
							"opendate": "12/31/1999"
							"opentime": "1:00 AM"
							"closedate": "1/1/2000"
							"closetime": "1:00 PM"
							"total": "100"
							"tries": "1"
							"late": "yes"
							"text": ""
						}
						.end (err, res)!->
							expect res.status .to.equal 400
							cont err
			]
			done err
		it "should not edit an assignment without an aid", (done)!->
			err <- async.waterfall [
				(cont)!->
					admin
						.get "/test/getaid/cps1234?title=admin"
						.end (err, res)!->
							cont err, res.body
				(aid, cont)!->
					admin
						.post "/c/#{courseId}/assignment/#{aid.0._id.toString()}/edit?hmo=PUT"
						.send {
							"title": aid.0.title
							"opendate": "12/31/1999"
							"opentime": "1:00 AM"
							"closedate": "1/1/2000"
							"closetime": "1:00 PM"
							"total": "100"
							"tries": "1"
							"late": "yes"
							"text": ""
						}
						.end (err, res)!->
							expect res.status .to.match /^(4)/
							cont err
			]
			done err
		it "should submit an attempt", (done)!->
			err <- async.waterfall [
				(cont)!->
					admin
						.get "/test/getaid/cps1234?title=admin"
						.end (err, res)!->
							cont err, res.body
				(aid,cont)!->
					admin
						.post "/c/#{courseId}/assignment/#{aid.0._id.toString()}/attempt"
						.send {
							"text":"adminAttempt"
						}
						.end (err, res)!->
							expect res.status .to.match /^(2|3)/
							expect res.header.location .to.match /^\/c\/.{24}\/attempt\/.{24}\/?/i
							cont err
			]
			done err
		it "should grade an assignment", (done)!->
			this.timeout = 3000
			err <- async.waterfall [
				(cont)!->
					admin
						.get "/test/getaid/cps1234?title=admin"
						.end (err, res)!->
							cont err, res.body
				(assign,cont)!->
					admin
						.get "/test/getattempt/cps1234?title=admin&text=adminAttempt"
						.end (err, res)!->
							cont err, assign, res.body
				(assign,attempt,cont)!->
					admin
						.post "/c/#{courseId}/attempt/#{attempt.0._id.toString()}/grade"
						.send {
							"points": "10"
						}
						.expect 302
						.end (err, res)!->
							expect res.header.location .to.match /^\/c\/.{24}\/attempt\/.{24}\/?\?success\=yes\&verb\=graded/i
							cont err
			]
			done err
		it "should return the delete assignment view", (done)!->
			err <- async.waterfall [
				(cont)!->
					admin
						.get "/test/getaid/cps1234?title=admin"
						.end (err, res)!->
							cont err, res.body
				(aid,cont)!->
					admin
						.get "/c/#{courseId}/assignment/#{aid.0._id}/delete"
						.end (err, res)!->
							expect res.status .to.equal 200
							cont err
			]
			done err
		it "should delete an assignment", (done)!->
			err <- async.waterfall [
				(cont)!->
					admin
						.get "/test/getaid/cps1234?title=admin"
						.end (err, res)!->
							cont err, res.body
				(aid,cont)!->
					admin
						.post "/c/#{courseId}/assignment/#{aid.0._id.toString()}/delete?hmo=DELETE"
						.send {
							"aid":aid.0._id
						}
						.end (err, res)!->
							expect res.status .to.equal 302
							expect res.header.location .to.match /^\/c\/.{24}\/assignments\/?/i
							cont err
			]
			done err
		it "should see the grades view", (done)!->
			admin
				.get "/c/#{courseId}/grades"
				.end (err, res)!->
					expect res.status .to.match /200/
					done err

	describe "(User: Faculty)", (...)!->
		it "should return the assignment default view", (done)!->
			faculty
				.get "/c/#{courseId}/assignments"
				.end (err, res)!->
					expect res.status .to.equal 200
					done err
		it "should return the create assignment view", (done)!->
			faculty
				.get "/c/#{courseId}/assignments/new"
				.end (err, res)!->
					expect res.status .to.equal 200
					done err
		it "should create an assignment", (done)!->
			faculty
				.post "/c/#{courseId}/assignments/new"
				.send {
					"title":"faculty"
					"opendate":"2/1/2000"
					"opentime":"1:00 AM"
					"closedate":"1/1/3000"
					"closetime":"1:00 PM"
					"total":"100"
					"tries":"1"
					"late":"yes"
					"text":"you will fail!"
				}
				.end (err, res)!->
					expect res.status .to.equal 302
					expect res.header.location .to.match /^\/c\/.{24}\/assignment\/.{24}\/?/i
					done err
		it "should return an assignment", (done)!->
			err <- async.waterfall [
				(cont)!->
					faculty
						.get "/test/getaid/cps1234?title=faculty"
						.end (err, res)!->
							cont err, res.body
				(aid,cont)!->
					faculty
						.get "/c/#{courseId}/assignment/#{aid.0._id.toString()}"
						.end (err, res)!->
							expect res.status .to.equal 200
							cont err
			]
			done err
		it "should return the edit assignment view", (done)!->
			err <- async.waterfall [
				(cont)!->
					faculty
						.get "/test/getaid/cps1234?title=faculty"
						.end (err, res)!->
							cont err, res.body
				(aid,cont)!->
					faculty
						.get "/c/#{courseId}/assignment/#{aid.0._id}/edit"
						.end (err, res)!->
							expect res.status .to.equal 200
							cont err
			]
			done err
		it "should edit an assignment", (done)!->
			err <- async.waterfall [
				(cont)!->
					faculty
						.get "/test/getaid/cps1234?title=faculty"
						.end (err, res)!->
							cont err, res.body
				(aid, cont)!->
					faculty
						.post "/c/#{courseId}/assignment/#{aid.0._id.toString()}/edit?hmo=PUT"
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
						.end (err, res)!->
							expect res.status .to.equal 302
							expect res.header.location .to.match /^\/c\/.{24}\/assignment\/.{24}\/?/i
							cont err
			]
			done err
		it "should submit an attempt", (done)!->
			err <- async.waterfall [
				(cont)!->
					faculty
						.get "/test/getaid/cps1234?title=faculty"
						.end (err, res)!->
							cont err, res.body
				(aid,cont)!->
					faculty
						.post "/c/#{courseId}/assignment/#{aid.0._id.toString()}/attempt"
						.send {
							"text":"facultyAttempt"
						}
						.end (err, res)!->
							expect res.status .to.match /^(2|3)/
							expect res.header.location .to.match /^\/c\/.{24}\/attempt\/.{24}\/?/i
							cont err
			]
			done err
		it "should grade an assignment", (done)!->
			this.timeout = 3000
			err <- async.waterfall [
				(cont)!->
					faculty
						.get "/test/getaid/cps1234?title=faculty"
						.end (err, res)!->
							cont err, res.body
				(assign,cont)!->
					faculty
						.get "/test/getattempt/cps1234?title=faculty&text=facultyAttempt"
						.end (err, res)!->
							cont err, assign, res.body
				(assign,attempt,cont)!->
					faculty
						.post "/c/#{courseId}/attempt/#{attempt.0._id.toString()}/grade"
						.send {
							"points": "10"
						}
						.expect 302
						.end (err, res)!->
							expect res.header.location .to.match /^\/c\/.{24}\/attempt\/.{24}\/?\?success\=yes\&verb\=graded/i
							cont err
			]
			done err
		it "should not negatively grade an assignment", (done)!->
			this.timeout = 3000
			err <- async.waterfall [
				(cont)!->
					faculty
						.get "/test/getaid/cps1234?title=faculty"
						.end (err, res)!->
							cont err, res.body
				(assign,cont)!->
					faculty
						.get "/test/getattempt/cps1234?title=faculty&text=facultyAttempt"
						.end (err, res)!->
							cont err, assign, res.body
				(assign,attempt,cont)!->
					faculty
						.post "/c/#{courseId}/attempt/#{attempt.0._id.toString()}/grade"
						.send {
							"points": "-10"
						}
						.expect 400
						.end (err, res)!->
							# expect res.header.location .to.match /^\/c\/.{24}\/attempt\/.{24}\/?\?success\=yes\&verb\=graded/i
							cont err
			]
			done err
		it "should return the delete assignment view", (done)!->
			err <- async.waterfall [
				(cont)!->
					faculty
						.get "/test/getaid/cps1234?title=faculty"
						.end (err, res)!->
							cont err, res.body
				(aid,cont)!->
					faculty
						.get "/c/#{courseId}/assignment/#{aid.0._id}/delete"
						.end (err, res)!->
							expect res.status .to.equal 200
							cont err
			]
			done err
		it "should delete an assignment", (done)!->
			err <- async.waterfall [
				(cont)!->
					faculty
						.get "/test/getaid/cps1234?title=faculty"
						.end (err, res)!->
							cont err, res.body
				(aid,cont)!->
					faculty
						.post "/c/#{courseId}/assignment/#{aid.0._id.toString()}/delete?hmo=DELETE"
						.send {
						}
						.end (err, res)!->
							expect res.status .to.equal 302
							expect res.header.location .to.match /^\/c\/.{24}\/assignments\/?/i
							cont err
			]
			done err
		it "should see the grades view", (done)!->
			faculty
				.get "/c/#{courseId}/grades"
				.end (err, res)!->
					expect res.status .to.match /200/
					done err

	describe "(User: Non-Faculty)", (done)!->
		before (done)!->
			this.timeout = 0
			err <- async.parallel [
				(next)!->
					faculty
						.post "/c/#{courseId}/assignments/new"
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
						.end (err, res)!->
							expect res.status .to.equal 302
							expect res.header.location .to.match /^\/c\/.{24}\/assignment\/.{24}\/?/i
							next err
			]
			done err if err
			err <- async.waterfall [
				(water)!->
					faculty
						.get "/logout"
						.end (err, res)!->
							water err
				(water)!->
					faculty
						.post "/login"
						.send {
							"username": "gfaculty"
							"password": "password"
						}
						.end (err, res)!->
							expect res.status .to.equal 302
							water err
			]
			done err
		after (done)!->
			err <- async.parallel [
				(next)!->
					err <- async.waterfall [
						(water)!->
							faculty
								.get "/logout"
								.end (err, res)!->
									water err
						(water)!->
							faculty
								.post "/login"
								.send {
									"username": "faculty"
									"password": "password"
								}
								.end (err, res)!->
									expect res.status .to.equal 302
									water err
					]
					next err
				(next)!->
					# clean up outsideFaculty
					err <- async.waterfall [
						(water)!->
							admin
								.get "/test/getaid/cps1234?title=outsideFaculty"
								.end (err, res)!->
									water err, res.body
						(aid,water)!->
							admin
								.post "/c/#{courseId}/assignment/#{aid.0._id.toString()}/delete?hmo=DELETE"
								.send {
								}
								.end (err, res)!->
									expect res.status .to.equal 302
									water err
					]
					next err
			]
			done err
		it "should not return the assignment default view", (done)!->
			faculty
				.get "/c/#{courseId}/assignments"
				.end (err, res)!->
					expect res.status .to.not.equal 200
					done err
		it "should not return the create assignment view", (done)!->
			faculty
				.get "/c/#{courseId}/assignments/new"
				.end (err, res)!->
					expect res.status .to.not.equal 200
					done err
		it "should not create an assignment", (done)!->
			faculty
				.post "/c/#{courseId}/assignments/new"
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
				.end (err, res)!->
					expect res.status .to.match /^(3|4)/
					expect res.header.location .to.not.equal /^\/c\/.{24}\/assignment\/.{24}\/?/i
					done err
		it "should not return an assignment", (done)!->
			err <- async.waterfall [
				(cont)!->
					admin
						.get "/test/getaid/cps1234?title=outsideFaculty"
						.end (err, res)!->
							cont err, res.body
				(aid,cont)!->
					faculty
						.get "/c/#{courseId}/assignment/#{aid.0._id.toString()}"
						.end (err, res)!->
							expect res.status .to.not.equal 200
							cont err
			]
			done err
		it "should not return the edit assignment view", (done)!->
			err <- async.waterfall [
				(cont)!->
					faculty
						.get "/test/getaid/cps1234?title=outsideFaculty"
						.end (err, res)!->
							cont err, res.body
				(aid,cont)!->
					faculty
						.get "/c/#{courseId}/assignment/#{aid.0._id}/edit"
						.end (err, res)!->
							expect res.status .to.not.equal 200
							cont err
			]
			done err
		it "should not edit an assignment", (done)!->
			err <- async.waterfall [
				(cont)!->
					faculty
						.get "/test/getaid/cps1234?title=outsideFaculty"
						.end (err, res)!->
							cont err, res.body
				(aid, cont)!->
					faculty
						.post "/c/#{courseId}/assignment/#{aid.0._id.toString()}/edit?hmo=PUT"
						.send {
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
						.end (err, res)!->
							expect res.status .to.match /^(3|4)/
							expect res.header.location .to.not.equal /^\/c\/.{24}\/assignment\/.{24}\/?/i
							cont err
			]
			done err
		it "should not submit an attempt", (done)!->
			err <- async.waterfall [
				(cont)!->
					faculty
						.get "/test/getaid/cps1234?title=outsideFaculty"
						.end (err, res)!->
							cont err, res.body
				(aid,cont)!->
					faculty
						.post "/c/#{courseId}/assignment/#{aid.0._id.toString()}/attempt"
						.send {
							"text":"facultyAttempt"
						}
						.expect 404
						.end (err, res)!->
							expect res.header.location .to.not.match /^\/c\/.{24}\/attempt\/.{24}\/?/i
							cont err
			]
			done err
		it "should not return the delete assignment view", (done)!->
			err <- async.waterfall [
				(cont)!->
					faculty
						.get "/test/getaid/cps1234?title=outsideFaculty"
						.end (err, res)!->
							cont err, res.body
				(aid,cont)!->
					faculty
						.get "/c/#{courseId}/assignment/#{aid.0._id}/delete"
						.end (err, res)!->
							expect res.status .to.not.equal 200
							cont err
			]
			done err
		it "should not delete an assignment", (done)!->
			err <- async.waterfall [
				(cont)!->
					faculty
						.get "/test/getaid/cps1234?title=outsideFaculty"
						.end (err, res)!->
							cont err, res.body
				(aid,cont)!->
					faculty
						.post "/c/#{courseId}/assignment/#{aid.0._id.toString()}/delete?hmo=DELETE"
						.send {
						}
						.end (err, res)!->
							expect res.status .to.match /^(3|4)/
							expect res.header.location .to.not.match /^\/c\/.{24}\/assignments\/?/
							cont err
			]
			done err
		it "should not see the grades view", (done)!->
			faculty
				.get "/c/#{courseId}/grades"
				.end (err, res)!->
					expect res.status .to.not.match /200/
					done err

	describe "(User: Student)", (...)!->
		before (done)!->
			faculty
				.post "/c/#{courseId}/assignments/new"
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
				.end (err, res)!->
					expect res.status .to.equal 302
					expect res.header.location .to.match /^\/c\/.{24}\/assignment\/.{24}\/?/i
					done err
		it "should return the assignment default view", (done)!->
			student
				.get "/c/#{courseId}/assignments"
				.end (err, res)!->
					expect res.status .to.equal 200
					done err
		it "should not create an assignment", (done)!->
			student
				.post "/c/#{courseId}/assignments/new"
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
				.end (err, res)!->
					# expect res.status .to.equal 302
					expect res.header.location .to.not.match /^\/c\/.{24}\/assignment\/.{24}\/?/i
					done err
		it "should not edit an assignment", (done)!->
			err <- async.waterfall [
				(cont)!->
					student
						.get "/test/getaid/cps1234?title=student"
						.end (err, res)!->
							cont err, res.body
				(aid, cont)!->
					student
						.post "/c/#{courseId}/assignment/#{aid.0._id.toString()}/edit?hmo=PUT"
						.send {
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
						.end (err, res)!->
							# expect res.status .to.equal 302
							expect res.header.location .to.not.match /^\/c\/.{24}\/assignment\/.{24}\/?/i # #{aid.0._id.toString()}"
							cont err
			]
			done err
		it "should not delete an assignment", (done)!->
			err <- async.waterfall [
				(cont)!->
					student
						.get "/test/getaid/cps1234?title=student"
						.end (err, res)!->
							cont err, res.body
				(aid,cont)!->
					student
						.post "/c/#{courseId}/assignment/#{aid.0._id.toString()}/delete?hmo=DELETE"
						.send {
						}
						.end (err, res)!->
							# expect res.status .to.not.equal 302
							expect res.header.location .to.not.match /^\/c\/.{24}\/assignment\/.{24}\/?/i
							cont err
			]
			done err
		it "should view a list of assignments", (done)!->
			student
				.get "/c/#{courseId}/assignments"
				.end (err, res)!->
					expect res.status .to.equal 200
					done err
		it "should view an assignment", (done)!->
			err <- async.waterfall [
				(cont)!->
					admin
						.get "/test/getaid/cps1234?title=student"
						.end (err, res)!->
							cont err, res.body
				(aid,cont)!->
					student
						.get "/c/#{courseId}/assignment/#{aid.0._id.toString()}"
						.end (err, res)!->
							expect res.status .to.equal 200
							cont err
			]
			done err
		it "should submit an attempt on an assignment", (done)!->
			err <- async.waterfall [
				(cont)!->
					student
						.post "/test/getaid/cps1234?title=student"
						.end (err, res)!->
							cont err, res.body
				(aid, cont)!->
					student
						.post "/c/#{courseId}/assignment/#{aid.0._id.toString()}/attempt"
						.send {
							"text":"studentAttempt"
						}
						.end (err, res)!->
							expect res.status .to.not.match /^(4|5)/i
							expect res.header.location .to.match /^\/c\/.{24}\/attempt\/.{24}\/?/i
							attemptid := res.header.location
							cont err
			]
			done err
		it "should view an attempt on an assignment", (done)!->
			student
				.get attemptid
				.end (err, res)!->
					done err, res.body
		it "should not grade an assignment", (done)!->
			this.timeout = 3000
			err <- async.waterfall [
				(cont)!->
					student
						.get "/test/getaid/cps1234?title=student"
						.end (err, res)!->
							cont err, res.body
				(assign,cont)!->
					student
						.get "/test/getattempt/cps1234?title=student&text=studentAttempt"
						.end (err, res)!->
							cont err, assign, res.body
				(assign,attempt,cont)!->
					student
						.post "/c/#{courseId}/attempt/#{attempt.0._id.toString()}/grade"
						.send {
							"points": "10"
						}
						.expect 302
						.end (err, res)!->
							expect res.header.location .to.match /^\//i
							cont err
			]
			done err
		it "should see the grades view", (done)!->
			student
				.get "/c/#{courseId}/grades"
				.end (err, res)!->
					expect res.status .to.match /200/
					done err

	describe "(User: Non-Student)", (...)!->
		before (done)!->
			faculty
				.post "/c/#{courseId}/assignments/new"
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
				.end (err, res)!->
					expect res.status .to.match /^(3|4)/
					expect res.header.location .to.match /^\/c\/.{24}\/assignment\/.{24}\/?/i
					done err
		before (done)!->
			student
				.get "/logout"
				.end (err, res)!->
					done err
		before (done)!->
			student
				.post "/login"
				.send {
					"username": "astudent"
					"password": "password"
				}
				.end (err, res)!->
					expect res.status .to.equal 302
					done err
		it "should not allow an outside student to create an assignment", (done)!->
			student
				.post "/c/#{courseId}/assignments/new"
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
				.end (err, res)!->
					expect res.status .to.match /^(3|4)/i
					expect res.header.location .to.not.match /^\/c\/.{24}\/assignment\/.{24}\/?/i
					done err
		it "should not allow an outside student to edit an assignment", (done)!->
			err <- async.waterfall [
				(cont)!->
					student
						.get "/test/getaid/cps1234?title=aUniqueTitle"
						.end (err, res)!->
							cont err, res.body
				(aid, cont)!->
					student
						.post "/c/#{courseId}/assignment/#{aid.0._id.toString()}/edit?hmo=PUT"
						.send {
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
						.end (err, res)!->
							expect res.status .to.match /^(3|4)/i
							expect res.header.location .to.not.match /^\/c\/.{24}\/assignment\/.{24}\/?/i
							cont err
			]
			done err
		it "should not allow an outside student to delete an assignment", (done)!->
			err <- async.waterfall [
				(cont)!->
					student
						.get "/test/getaid/cps1234?title=aUniqueTitle"
						.end (err, res)!->
							cont err, res.body
				(aid,cont)!->
					student
						.post "/c/#{courseId}/assignment/#{aid.0._id.toString()}/delete?hmo=DELETE"
						.send {
						}
						.end (err, res)!->
							expect res.status .to.match /^(3|4)/i
							expect res.header.location .to.not.match /^\/c\/.{24}\/assignments\/?/i
							cont err
			]
			done err
		it "should not allow an outside student to view a list of assignments", (done)!->
			student
				.get "/c/#{courseId}/assignments"
				.end (err, res)!->
					expect res.status .to.match /^(3|4)/i
					expect res.header.location .to.not.match /^\/c\/.{24}\/assignments\/?/i
					done err
		it "should not allow an outside student to view an assignment", (done)!->
			err <- async.waterfall [
				(cont)!->
					admin
						.get "/test/getaid/cps1234?title=aUniqueTitle"
						.end (err, res)!->
							cont err, res.body
				(aid,cont)!->
					student
						.get "/c/#{courseId}/assignment/#{aid.0._id.toString()}"
						.end (err, res)!->
							expect res.status .to.match /^(3|4)/i
							expect res.header.location .to.not.match /^\/c\/.{24}\/assignments\/?.{24}?\/?/i
							cont err
			]
			done err
		it "should not allow an outside student to submit an attempt on an assignment", (done)!->
			err <- async.waterfall [
				(cont)!->
					student
						.post "/test/getaid/cps1234?title=aUniqueTitle"
						.end (err, res)!->
							cont err, res.body
				(aid, cont)!->
					student
						.post "/c/#{courseId}/assignment/#{aid.0._id.toString()}/attempt"
						.send {
							"text":"something right here"
						}
						.end (err, res)!->
							expect res.headers.location .to.not.match /^\/c\/.{24}\/assignments\/.{24}?\/?.{24}?\/?/i
							cont err
			]
			done err
		it "should not allow an outside student to see the grades view", (done)!->
			student
				.get "/c/#{courseId}/grades"
				.end (err, res)!->
					expect res.status .to.not.match /200/
					done err

	describe "Crash Checks", (...)!->
		it "should not crash when creating/editing an assignment without opendate", (done)!->
			faculty
				.post "/c/#{courseId}/assignments/new"
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
				.end (err, res)!->
					expect res.status .to.not.match /^(4|5)/i
					expect res.header.location .to.match /^\/c\/.{24}\/assignment\/.{24}\/?/i
					done err
		it "should not crash when creating/editing an assignment without opentime", (done)!->
			faculty
				.post "/c/#{courseId}/assignments/new"
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
				.end (err, res)!->
					expect res.status .to.not.match /^(4|5)/i
					expect res.header.location .to.match /^\/c\/.{24}\/assignment\/.{24}\/?/i
					done err
		it "should not crash when creating/editing an assignment without opendate & opentime", (done)!->
			faculty
				.post "/c/#{courseId}/assignments/new"
				.send {
					"title":"title"
					"closedate":"1/1/2000"
					"closetime":"1:00 PM"
					"total":"100"
					"tries":"1"
					"late":"yes"
					"text":"you will fail!"
				}
				.end (err, res)!->
					expect res.status .to.not.match /^(4|5)/i
					expect res.header.location .to.match /^\/c\/.{24}\/assignment\/.{24}\/?/i
					done err
		it "should not crash when creating/editing an assignment without closedate", (done)!->
			faculty
				.post "/c/#{courseId}/assignments/new"
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
				.end (err, res)!->
					expect res.status .to.not.match /^(4|5)/i
					expect res.header.location .to.match /^\/c\/.{24}\/assignment\/.{24}\/?/i
					done err
		it "should not crash when creating/editing an assignment without closetime", (done)!->
			faculty
				.post "/c/#{courseId}/assignments/new"
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
				.end (err, res)!->
					expect res.status .to.not.match /^(4|5)/i
					expect res.header.location .to.match /^\/c\/.{24}\/assignment\/.{24}\/?/i
					done err
		it "should not crash when creating/editing an assignment without closedate & closetime", (done)!->
			faculty
				.post "/c/#{courseId}/assignments/new"
				.send {
					"title":"title"
					"opendate":"12/31/1999"
					"opentime":"1:00 AM"
					"total":"100"
					"tries":"1"
					"late":"yes"
					"text":"you will fail!"
				}
				.end (err, res)!->
					expect res.status .to.not.match /^(4|5)/i
					expect res.header.location .to.match /^\/c\/.{24}\/assignment\/.{24}\/?/i
					done err
		it "should not crash when creating/editing an assignment without points", (done)!->
			faculty
				.post "/c/#{courseId}/assignments/new"
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
				.end (err, res)!->
					expect res.status .to.not.match /^(4|5)/i
					expect res.header.location .to.match /^\/c\/.{24}\/assignment\/.{24}\/?/i
					done err
		it "should not allow creating/editing an assignment without a title", (done)!->
			faculty
				.post "/c/#{courseId}/assignments/new"
				.send {
					"opendate":"12/31/1999"
					"opentime":"1:00 AM"
					"closedate":"1/1/2000"
					"closetime":"1:00 PM"
					"tries":"1"
					"late":"yes"
					"text":"you will fail!"
				}
				.end (err, res)!->
					# expect res.status .to.not.match /^(4|5)/i
					expect res.header.location .to.not.match /^\/c\/.{24}\/assignment\/.{24}\/?/i
					done err
		it "should not allow creating/editing an assignment without a body", (done)!->
			faculty
				.post "/c/#{courseId}/assignments/new"
				.send {
					"title":"title"
					"opendate":"12/31/1999"
					"opentime":"1:00 AM"
					"closedate":"1/1/2000"
					"closetime":"1:00 PM"
					"tries":"1"
					"late":"yes"
				}
				.end (err, res)!->
					# expect res.status .to.not.match /^(4|5)/i
					expect res.header.location .to.not.match /^\/c\/.{24}\/assignment\/.{24}\/?/i
					done err
		it "should not allow creating/editing an assignment without tries", (done)!->
			faculty
				.post "/c/#{courseId}/assignments/new"
				.send {
					"title":"title"
					"opendate":"12/31/1999"
					"opentime":"1:00 AM"
					"closedate":"1/1/2000"
					"closetime":"1:00 PM"
					"late":"yes"
					"text":"you will fail!"
				}
				.end (err, res)!->
					# expect res.status .to.not.match /^(4|5)/i
					expect res.header.location .to.not.match /^\/c\/.{24}\/assignment\/.{24}\/?/i
					done err

	describe "Other Functions", (...)!->
		otherFunc = {}
		before (done)!->
			this.timeout = 0
			err <- async.waterfall [
				(water)!->
					student
						.get "/logout"
						.end (err, res)!->
							water err
				(water)!->
					student
						.post "/login"
						.send {
							"username": "student"
							"password": "password"
						}
						.end (err, res)!->
							expect res.status .to.equal 302
							water err
			]
			done err if err
			err <- async.parallel [
				(next)!->
					# for now < date
					faculty
						.post "/c/#{courseId}/assignments/new"
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
						.end (err, res)!->
							expect res.status .to.not.match /^(4|5)/i
							student
								.post "/test/getaid/cps1234?title=Early"
								.end (err, res)!->
									assignments = JSON.parse res.text
									otherFunc.Early = assignments.0._id
									next err
				(next)!->
					# for now > close
					faculty
						.post "/c/#{courseId}/assignments/new"
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
						.end (err, res)!->
							expect res.status .to.not.match /^(4|5)/i
							student
								.post "/test/getaid/cps1234?title=Late"
								.end (err, res)!->
									assignments = JSON.parse res.text
									otherFunc.Late = assignments.0._id
									next err
				(next)!->
					# for now > close & allowLate = true
					faculty
						.post "/c/#{courseId}/assignments/new"
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
						.end (err, res)!->
							expect res.status .to.not.match /^(4|5)/i
							student
								.post "/test/getaid/cps1234?title=allowLate"
								.end (err, res)!->
									assignments = JSON.parse res.text
									otherFunc.allowLate = assignments.0._id
									next err
				(next)!->
					# for attempts > allowed
					faculty
						.post "/c/#{courseId}/assignments/new"
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
						.end (err, res)!->
							expect res.status .to.not.match /^(4|5)/i
							student
								.post "/test/getaid/cps1234?title=None"
								.end (err, res)!->
									assignments = JSON.parse res.text
									otherFunc.None = assignments.0._id
									next err
			]
			done err
		after (done)!->
			this.timeout = 0
			# clean up outsideFaculty
			admin
				.get "/test/deleteassignments/cps1234"
				.end (err, res)!->
					done err
		it "should not allow early submissions", (done)!->
			student
				.post "/c/#{courseId}/assignment/#{otherFunc.Early}/attempt"
				.send {
					"text":"something"
				}
				.end (err, res)!->
					expect res.status .to.equal 400
					expect res.text .to.have.string "Allowed assignment submission window has not opened."
					done err
		it "should not allow late submissions if not allowed", (done)!->
			student
				.post "/c/#{courseId}/assignment/#{otherFunc.Late}/attempt"
				.send {
					"text":"something"
				}
				.end (err, res)!->
					expect res.status .to.equal 400
					expect res.text .to.have.string "Allowed assignment submission window has closed."
					done err
		it "should allow late submissions if allowed", (done)!->
			student
				.post "/c/#{courseId}/assignment/#{otherFunc.allowLate}/attempt"
				.send {
					"text":"something"
				}
				.end (err, res)!->
					expect res.status .to.not.match /^(4|5)/i
					done err
		it "should not allow more attempts than given", (done)!->
			student
				.post "/c/#{courseId}/assignment/#{otherFunc.None}/attempt"
				.send {
					"text":"something"
				}
				.end (err, res)!->
					expect res.status .to.equal 400
					expect res.text .to.have.string "You have no more attempts."
					done err

	describe "Other", (...)!->
		it "should give an error for bad assignment length", (done)!->
			student
				.get "/c/#{courseId}/assignments/1234"
				.end (err, res)!->
					expect res.status .to.match /^(3|4|5)/
					done err
		it "should give an error for bad attempt length", (done)!->
			admin
				.get "/c/#{courseId}/assignments/123456789012345678901234/1234"
				.end (err, res)!->
					expect res.status .to.match /^(3|4|5)/
					done err
		it "should give an error for a bad assignment", (done)!->
			admin
				.get "/c/#{courseId}/assignments/123456789012345678901234"
				.end (err, res)!->
					expect res.status .to.match /^(3|4|5)/
					done err
		it "should give an error for a bad attempt good assignment", (done)!->
			err <- async.waterfall [
				(cont)!->
					admin
						.post "/c/#{courseId}/assignments/new"
						.send {
							"title":"goodAssign"
							"opendate":"1/1/2000"
							"opentime":"1:00 AM"
							"closedate":"1/1/3000"
							"closetime":"1:00 PM"
							"total":"100"
							"tries":"1"
							"late":"yes"
							"text":"you will fail!"
						}
						.end (err, res)!->
							cont err
				(cont)!->
					admin
						.get "/test/getaid/cps1234?title=goodAssign"
						.end (err, res)!->
							cont err, res.body
				(aid, cont)!->
					admin
						.get "/c/#{courseId}/assignment/#{aid.0._id}/123456789012345678901234"
						.end (err, res)!->
							expect res.status .to.match /^(3|4|5)/
							cont err
			]
			done err
		it "should give an error for attempting to post with different action", (done)!->
			admin
				.post "/c/#{courseId}/assignments/anything"
				.send {}
				.end (err, res)!->
					expect res.status .to.match /^(3|4|5)/
					done err
		it "should give an error for attempting to put with different action", (done)!->
			admin
				.put "/c/#{courseId}/assignments/anything/?hmo=put"
				.send {}
				.end (err, res)!->
					expect res.status .to.match /^(3|4|5)/
					done err
		it "should give an error for attempting to delete with different action", (done)!->
			admin
				.delete "/c/#{courseId}/assignments/anything"
				.send {}
				.end (err, res)!->
					expect res.status .to.match /^(3|4|5)/
					done err
