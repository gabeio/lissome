require! {
	'chai' # assert lib
	'supertest' # request lib
	'del' # delete
}
app = require '../app'
req = supertest
expect = chai.expect
assert = chai.assert
should = chai.should!
var admin, agent, csrf, acsrf
describe "Base" ->
	before (done)->
		app.locals.db # somehow check this is connected
		done!
	before (done)-> # setup basic user
		agent := req.agent app
		done!
	before (done)-> # get csrf cookie & token
		agent
			.get '/get/test/on/csrf'
			.end (err, res)->
				csrf := res.text
				done err
	before (done)->
		admin := req.agent app
		done!
	before (done)->
		admin
			.get '/get/test/on/csrf'
			.end (err, res)->
				acsrf := res.text
				done err
	before (done)->
		admin
			.post '/post/test/on/admin'
			.send { _csrf: acsrf } # all POST requests need csrf do not remove
			.end (err, res)->
				expect res.status .to.equal 200
				done err
	before (done)->
		admin
			.get '/get/test/on/admin'
			.send { _csrf: acsrf } # all POST requests need csrf do not remove
			.end (err, res)->
				expect res.status .to.equal 200
				done err
	describe "Index", (...)->
		it "should respond to a GET", (done)->
			req app
				.get '/'
				.expect 200
				.end (err, res)->
					expect res.status .to.equal 200
					expect res.body .to.not.be.a 'null'
					done err
		it "should error to a POST", (done)->
			req app
				.post '/'
				.end (err, res)->
					expect res.status .to.not.equal 200
					done err
		it "should error to a PUT", (done)->
			req app
				.put '/'
				.end (err, res)->
					expect res.status .to.not.equal 200
					done err
		it "should error to a DELETE", (done)->
			req app
				.delete '/'
				.end (err, res)->
					expect res.status .to.not.equal 200
					done err
	describe "Index w/ csrf", (...)->
		it "should error to a POST", (done)->
			agent
				.post '/'
				.send {
					'_csrf': csrf
				}
				.end (err, res)->
					expect res.status .to.not.equal 200
					expect res.text .to.equal 'Cannot POST /\n'
					done err
		it "should error to a PUT", (done)->
			agent
				.put '/'
				.send { _csrf:csrf }
				.end (err, res)->
					expect res.status .to.not.equal 200
					expect res.text .to.equal 'Cannot PUT /\n'
					done err
		it "should error to a DELETE", (done)->
			agent
				.delete '/'
				.send {'_csrf':csrf}
				.end (err, res)->
					expect res.status .to.not.equal 200
					expect res.text .to.equal 'Cannot DELETE /\n'
					done err
