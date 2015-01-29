require! {
	'chai' # assert lib
	'supertest' # request lib
	'del' # delete
}
req = supertest
expect = chai.expect
assert = chai.assert
should = chai.should!
var app, admin, agent, csrf, acsrf
describe "Teacher" ->
	before (done)-> # setup app
		# process.env.NODE_ENV := 'production'
		app := require '../app'
		done!
	before (done)-> # setup basic user
		agent := req.agent app
		done!
	before (done)-> # get csrf cookie & token
		agent
			.get '/get/test/on/csrf'
			.end (err, res)->
				expect res.status .to.equal 200
				csrf := res.text
				done err
	before (done)->
		admin := req.agent app
		done!
	before (done)->
		admin
			.get '/get/test/on/csrf'
			.expect 200
			.end (err, res)->
				expect res.status .to.equal 200
				acsrf := res.text
				done err
	before (done)->
		admin
			.post '/post/test/on/admin'
			.send { _csrf: acsrf } # all POST requests need csrf do not remove
			.expect 200
			.end (err, res)->
				expect res.status .to.equal 200
				done err
