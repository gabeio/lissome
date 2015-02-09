require! {
	'chai' # assert lib
	'supertest' # request lib
	'del' # delete
	'async'
}
app = require '../app'
req = supertest
expect = chai.expect
assert = chai.assert
should = chai.should!
var agent
describe "Base" ->
	before (done)-> # setup basic user
		agent := req.agent app
		done!
	before (done)->
		this.timeout 0
		console.log '\tpausing to allow mongodb connection'
		/*readyState = setInterval (done)->
			console.log app.locals.db.readyState
			if app.locals.db?
				if app.locals.db.readyState is 1
					clearInterval readyState
					done
		, 100*/
		setTimeout done, 2000

	describe "Index", (...)->
		it "should respond to a GET", (done)->
			agent
				.get '/'
				.end (err, res)->
					expect res.status .to.equal 302
					/*expect res.body .to.not.be.a 'null'*/
					done err
		it "should error to a POST", (done)->
			agent
				.post '/'
				.end (err, res)->
					expect res.status .to.not.equal 200
					done err
		it "should error to a PUT", (done)->
			agent
				.put '/'
				.end (err, res)->
					expect res.status .to.not.equal 200
					done err
		it "should error to a DELETE", (done)->
			agent
				.delete '/'
				.end (err, res)->
					expect res.status .to.not.equal 200
					done err

	describe "Login/Logout", (...)->
		it "should 200 to a GET", (done)->
			agent
				.get '/login'
				.end (err, res)->
					expect res.status .to.equal 200
					# expect res.text .to.
					done err
		it "should ignore everything else to login w/o credentials", (done)->
			agent
				.put '/login'
				.send {
					'username':'gibberish'
					'password':'idk'
					'anything':'else'
				}
				.end (err, res)->
					expect res.status .to.not.equal 200
					agent
						.delete '/login'
						.send {
							'username':'gibberish'
							'password':'idk'
							'anything':'else'
						}
						.end (err, res)->
							expect res.status .to.not.equal 200
							done err
		it "should logout", (done)->
			agent
				.get '/logout'
				.end (err, res)->
					expect res.status .to.equal 302
					/*expect res.headers.location .to.equal '/login'*/
					done!
		it "should 302 to a POST w/ student credentials w/o type", (done)->
			agent
				.post '/login'
				.send {
					'username': 'Student'
					'password': 'password'
				}
				.end (err, res)->
					expect res.status .to.equal 302
					done err
		it "should logout", (done)->
			agent
				.get '/logout'
				.end (err, res)->
					expect res.status .to.equal 302
					/*expect res.headers.location .to.equal '/login'*/
					done!
		it "should 302 to a POST w/ student credentials w/ type", (done)->
			agent
				.post '/login'
				.send {
					'username': 'Student'
					'password': 'password'
					'type': 'Student'
				}
				.end (err, res)->
					expect res.status .to.equal 302
					done err
		it "should logout", (done)->
			agent
				.get '/logout'
				.end (err, res)->
					expect res.status .to.equal 302
					done!
		it "should ignore everything else to login w/ student credentials", (done)->
			agent
				.put '/login'
				.send {
					'username':'gibberish'
					'password':'idk'
					'anything':'else'
				}
				.end (err, res)->
					expect res.status .to.not.equal 200
					agent
						.delete '/login'
						.send {
							'username':'gibberish'
							'password':'idk'
							'anything':'else'
						}
						.end (err, res)->
							expect res.status .to.not.equal 200
							done err
		it "should logout", (done)->
			agent
				.get '/logout'
				.end (err, res)->
					expect res.status .to.equal 302
					/*expect res.headers.location .to.equal '/login'*/
					done err
		it "should 302 to a POST w/ faculty credentials", (done)->
			agent
				.post '/login'
				.send {
					'username': 'Faculty'
					'password': 'password'
					'type': 'Faculty'
				}
				.end (err, res)->
					expect res.status .to.equal 302
					done err
		it "should ignore everything else to login w/ faculty credentials", (done)->
			agent
				.put '/login'
				.send {
					'username':'gibberish'
					'password':'idk'
					'anything':'else'
				}
				.end (err, res)->
					expect res.status .to.not.equal 200
					agent
						.delete '/login'
						.send {
							'username':'gibberish'
							'password':'idk'
							'anything':'else'
						}
						.end (err, res)->
							expect res.status .to.not.equal 200
							done err
		it "should logout", (done)->
			agent
				.get '/logout'
				.end (err, res)->
					expect res.status .to.equal 302
					/*expect res.headers.location .to.equal '/login'*/
					done err
		it "should 302 to a POST w/ admin credentials", (done)->
			agent
				.post '/login'
				.send {
					'username': 'Admin'
					'password': 'password'
					'type': 'Admin'
				}
				.end (err, res)->
					expect res.status .to.equal 302
					done err
		it "should ignore everything else to login w/ admin credentials", (done)->
			agent
				.put '/login'
				.send {
					'username':'gibberish'
					'password':'idk'
					'anything':'else'
				}
				.end (err, res)->
					expect res.status .to.not.equal 200
					agent
						.delete '/login'
						.send {
							'username':'gibberish'
							'password':'idk'
							'anything':'else'
						}
						.end (err, res)->
							expect res.status .to.not.equal 200
							done err
		it "should logout", (done)->
			agent
				.get '/logout'
				.end (err, res)->
					expect res.status .to.equal 302
					/*expect res.headers.location .to.equal '/login'*/
					done err
		it "should fail for a blank student", (done)->
			agent
				.post '/login'
				.send {
					'username': ''
					'password': ''
				}
				.end (err, res)->
					expect res.text .to.have.string 'username not found'
					expect res.headers.location .to.be.an 'undefined'
					done err
		it "should fail for a blank faculty", (done)->
			agent
				.post '/login'
				.send {
					'username': ''
					'password': ''
					'type':'Faculty'
				}
				.end (err, res)->
					expect res.text .to.have.string 'username not found'
					expect res.headers.location .to.be.an 'undefined'
					done err
		it "should fail for a blank admin", (done)->
			agent
				.post '/login'
				.send {
					'username': ''
					'password': ''
					'type':'Admin'
				}
				.end (err, res)->
					expect res.text .to.have.string 'username not found'
					expect res.headers.location .to.be.an 'undefined'
					done err
		it "should fail for a good student username bad password", (done)->
			agent
				.post '/login'
				.send {
					'username': 'Student'
					'password': ''
				}
				.end (err, res)->
					expect res.text .to.have.string 'bad login credentials'
					done err
		it "should fail for a good faculty username bad password", (done)->
			agent
				.post '/login'
				.send {
					'username': 'Faculty'
					'password': ''
					'type':'Faculty'
				}
				.end (err, res)->
					expect res.text .to.have.string 'bad login credentials'
					done err
		it "should fail for a good admin username bad password", (done)->
			agent
				.post '/login'
				.send {
					'username': 'Admin'
					'password': ''
					'type':'Admin'
				}
				.end (err, res)->
					expect res.text .to.have.string 'bad login credentials'
					done err

	/*describe "Course", (...)->
		before
		it "should"*/

	after (done)->
		this.timeout 0
		app.locals.db.close!
		done!

	# describe "Dashboard", (...)->
	# 	it "", (done)->
	# 		...
