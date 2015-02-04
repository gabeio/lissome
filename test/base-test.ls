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
var admin, faculty, student, outside
describe "Base" ->
	before (done)-> # setup basic user
		admin := req.agent app
		done!
	before (done)->
		admin
			.get '/test/getadmin'
			.end (err, res)->
				done!
	before (done)->
		faculty := req.agent app
		done!
	before (done)->
		admin
			.get '/test/getfaculty'
			.end (err, res)->
				done!
	before (done)-> # setup basic user
		student := req.agent app
		done!
	before (done)->
		admin
			.get '/test/getstudent'
			.end (err, res)->
				done!
	before (done)->
		outside := req.agent app
		done!

	describe "Index", (...)->
		it "should respond to a GET", (done)->
			req app
				.get '/'
				.end (err, res)->
					expect res.status .to.equal 302
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

	describe "Login", (...)->
		it "should 200 to a GET", (done)->
			outside
				.get '/login'
				.end (err, res)->
					expect res.status .to.equal 200
					# expect res.text .to.
					done err
		it "should 200 to a POST w/ student credentials", (done)->
			student
				.post '/login'
				.send {
					'username': 'astudent'
					'password': 'password'
				}
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should 200 to a POST w/ faculty credentials", (done)->
			faculty
				.post '/login'
				.send {
					'username': 'a'
					'password': 'password'
					'type': 'faculty'
				}
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should 200 to a POST w/ admin credentials", (done)->
			admin
				.post '/login'
				.send {
					'username': 'a'
					'password': 'password'
					'type': 'admin'
				}
				.end (err, res)->
					expect res.status .to.equal 200
					done err
		it "should ignore everything else to login w/o credentials", (done)->
			outside
				.put '/login'
				.send {
					'username':'gibberish'
					'password':'idk'
					'anything':'else'
				}
				.end (err, res)->
					expect res.status .to.not.equal 200
					outside
						.delete '/login'
						.send {
							'username':'gibberish'
							'password':'idk'
							'anything':'else'
						}
						.end (err, res)->
							expect res.status .to.not.equal 200
							done err
		it "should ignore everything else to login w/ student credentials", (done)->
			student
				.put '/login'
				.send {
					'username':'gibberish'
					'password':'idk'
					'anything':'else'
				}
				.end (err, res)->
					expect res.status .to.not.equal 200
					student
						.delete '/login'
						.send {
							'username':'gibberish'
							'password':'idk'
							'anything':'else'
						}
						.end (err, res)->
							expect res.status .to.not.equal 200
							done err
		it "should ignore everything else to login w/ faculty credentials", (done)->
			faculty
				.put '/login'
				.send {
					'username':'gibberish'
					'password':'idk'
					'anything':'else'
				}
				.end (err, res)->
					expect res.status .to.not.equal 200
					faculty
						.delete '/login'
						.send {
							'username':'gibberish'
							'password':'idk'
							'anything':'else'
						}
						.end (err, res)->
							expect res.status .to.not.equal 200
							done err
		it "should ignore everything else to login w/ admin credentials", (done)->
			admin
				.put '/login'
				.send {
					'username':'gibberish'
					'password':'idk'
					'anything':'else'
				}
				.end (err, res)->
					expect res.status .to.not.equal 200
					admin
						.delete '/login'
						.send {
							'username':'gibberish'
							'password':'idk'
							'anything':'else'
						}
						.end (err, res)->
							expect res.status .to.not.equal 200
							done err

	# describe "Dashboard", (...)->
	# 	it "", (done)->
	# 		...
