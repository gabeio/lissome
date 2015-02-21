require! {
	'chai' # assert lib
	'supertest'
	'del' # delete
	'async'
}
req = supertest
expect = chai.expect
assert = chai.assert
should = chai.should!
var app, agent, student, faculty, admin
describe "Core" ->
	before (done)->
		app := require '../lib/app'
		done!
	before (done)-> # setup user agents
		agent := req.agent app
		student := req.agent app
		faculty := req.agent app
		admin := req.agent app
		done!
	before (done)->
		# this is to allow db connection/app setup
		this.timeout 0
		setTimeout done, 5000

	describe "Index", (...)->
		it "should respond to a GET", (done)->
			agent
				.get '/'
				.end (err, res)->
					expect res.status .to.equal 302
					# expect res.body .to.not.be ''
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
	describe "Login", (...)->
		afterEach (complete)->
			<- async.parallel [
				(done)->
					agent
						.get '/logout'
						.end (err, res)->
							done err
				(done)->
					student
						.get '/logout'
						.end (err, res)->
							done err
				(done)->
					faculty
						.get '/logout'
						.end (err, res)->
							done err
				(done)->
					admin
						.get '/logout'
						.end (err, res)->
							done err
			]
			complete!
		it "should respond to a GET", (done)->
			agent
				.get '/login'
				.end (err, res)->
					expect res.status .to.equal 200
					# expect res.text .to.
					done err
		it "should login with valid credentials", (done)->
			err <- async.parallel [
				(cont)->
					student
						.post '/login'
						.send {
							'username': 'Student'
							'password': 'password'
						}
						.end (err, res)->
							expect res.status .to.equal 302
							cont err
				(cont)->
					faculty
						.post '/login'
						.send {
							'username': 'Faculty'
							'password': 'password'
						}
						.end (err, res)->
							expect res.status .to.equal 302
							cont err
				(cont)->
					admin
						.post '/login'
						.send {
							'username': 'Admin'
							'password': 'password'
						}
						.end (err, res)->
							expect res.status .to.equal 302
							cont err
			]
			done err
		it "shouldn't matter how the user caps the username (student)", (done)->
			student
				.post '/login'
				.send {
					'username': 'stuDENT'
					'password': 'password'
				}
				.end (err, res)->
					expect res.status .to.equal 302
					done err
		it "shouldn't matter how the user caps the username (faculty)", (done)->
			faculty
				.post '/login'
				.send {
					'username': 'facULTY'
					'password': 'password'
				}
				.end (err, res)->
					expect res.status .to.equal 302
					done err
		it "shouldn't matter how the user caps the username (admin)", (done)->
			admin
				.post '/login'
				.send {
					'username': 'adMIN'
					'password': 'password'
				}
				.end (err, res)->
					expect res.status .to.equal 302
					done err
		it "should ignore put/delete to login as outside", (done)->
			err <- async.parallel [
				(cont)->
					agent
						.put '/login'
						.send {
							'username':'gibberish'
							'password':'idk'
							'anything':'else'
						}
						.end (err, res)->
							expect res.status .to.not.equal 200
							cont err
				(cont)->
					agent
						.delete '/login'
						.send {
							'username':'gibberish'
							'password':'idk'
							'anything':'else'
						}
						.end (err, res)->
							expect res.status .to.not.equal 200
							cont err
			]
			done err
		it "should ignore put/delete to login as student", (done)->
			student
				.post '/login'
				.send {
					'username': 'stuDENT'
					'password': 'password'
				}
				.end (err, res)->
					err <- async.parallel [
						(cont)->
							student
								.put '/login'
								.send {
									'username':'gibberish'
									'password':'idk'
									'anything':'else'
								}
								.end (err, res)->
									expect res.status .to.not.equal 200
									cont err
						(cont)->
							student
								.delete '/login'
								.send {
									'username':'gibberish'
									'password':'idk'
									'anything':'else'
								}
								.end (err, res)->
									expect res.status .to.not.equal 200
									cont err
					]
					done err
		it "should ignore put/delete to login as faculty", (done)->
			faculty
				.post '/login'
				.send {
					'username': 'Faculty'
					'password': 'password'
				}
				.end (err, res)->
					err <- async.parallel [
						(cont)->
							faculty
								.put '/login'
								.send {
									'username':'gibberish'
									'password':'idk'
									'anything':'else'
								}
								.end (err, res)->
									expect res.status .to.not.equal 200
									cont err
						(cont)->
							faculty
								.delete '/login'
								.send {
									'username':'gibberish'
									'password':'idk'
									'anything':'else'
								}
								.end (err, res)->
									expect res.status .to.not.equal 200
									cont err
					]
					done err
		it "should ignore put/delete to login as admin", (done)->
			admin
				.post '/login'
				.send {
					'username': 'Admin'
					'password': 'password'
				}
				.end (err, res)->
					err <- async.parallel [
						(cont)->
							admin
								.put '/login'
								.send {
									'username':'gibberish'
									'password':'idk'
									'anything':'else'
								}
								.end (err, res)->
									expect res.status .to.not.equal 200
									cont err
						(cont)->
							admin
								.delete '/login'
								.send {
									'username':'gibberish'
									'password':'idk'
									'anything':'else'
								}
								.end (err, res)->
									expect res.status .to.not.equal 200
									cont err
					]
					done err
		it "should fail for a blank student", (done)->
			student
				.post '/login'
				.send {
					'username': ''
					'password': ''
				}
				.end (err, res)->
					expect res.text .to.have.string 'bad login credentials'
					expect res.headers.location .to.be.an 'undefined'
					done err
		it "should fail for a blank faculty", (done)->
			faculty
				.post '/login'
				.send {
					'username': ''
					'password': ''
				}
				.end (err, res)->
					expect res.text .to.have.string 'bad login credentials'
					expect res.headers.location .to.be.an 'undefined'
					done err
		it "should fail for a blank admin", (done)->
			admin
				.post '/login'
				.send {
					'username': ''
					'password': ''
				}
				.end (err, res)->
					expect res.text .to.have.string 'bad login credentials'
					expect res.headers.location .to.be.an 'undefined'
					done err
		it "should fail for a good student username bad password", (done)->
			student
				.post '/login'
				.send {
					'username': 'Student'
					'password': ''
				}
				.end (err, res)->
					expect res.text .to.have.string 'bad login credentials'
					done err
		it "should fail for a good faculty username bad password", (done)->
			faculty
				.post '/login'
				.send {
					'username': 'Faculty'
					'password': ''
				}
				.end (err, res)->
					expect res.text .to.have.string 'bad login credentials'
					done err
		it "should fail for a good admin username bad password", (done)->
			admin
				.post '/login'
				.send {
					'username': 'Admin'
					'password': ''
				}
				.end (err, res)->
					expect res.text .to.have.string 'bad login credentials'
					done err
		it "shouldn't crash for just username defined", (done)->
			err <- async.parallel [
				(cont)->
					student
						.post '/login'
						.send {
							'username':'student'
						}
						.end (err, res)->
							# expect res.text .to.not.be ''
							expect res.text .to.have.string 'bad login credentials'
							# expect res.status .to.equal 401
							cont err
				(cont)->
					faculty
						.post '/login'
						.send {
							'username':'faculty'
						}
						.end (err, res)->
							# expect res.text .to.not.be ''
							expect res.text .to.have.string 'bad login credentials'
							# expect res.status .to.equal 401
							cont err
				(cont)->
					admin
						.post '/login'
						.send {
							'username':'admin'
						}
						.end (err, res)->
							# expect res.text .to.not.be ''
							expect res.text .to.have.string 'bad login credentials'
							# expect res.status .to.equal 401
							cont err
			]
			done err

	# describe "Dashboard", (...)->
	# 	it.skip "should show any changes to any classes a student presently enrolled in"	
