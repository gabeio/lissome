module.exports = (app)->
	async = app.locals.async
	winston = app.locals.winston
	app
		..use (err, req, res, next)->
			async.parallel [
				!->
					# ALWAYS LOG
					winston.error 'error: ' + err + '\turl: ' + req.url
				!->
					if err?
						if err.code is 'EBADCSRFTOKEN'
							res.status 403 .send 'Bad Request' #.render 'error' {err:'Bad Request'}
						else
							# console.log err.message
							switch err.message
							| 'NOT FOUND'
								res.status 404 .render 'error' { err:'Not Found' }
							| 'NOT XHR'
								res.status 400 .render 'error' { err:'Not Sent Correctly' }
							| 'UNAUTHORIZED'
								if req.session.auth?
									res.status 302 .redirect '/' # logged in
								else
									res.status 302 .redirect '/login' # not logged in
								# res.status 401 .render 'error' { err:'Unauthorized' }
							| 'UNKNOWN NEEDS'
								res.status 401 .render 'error' { err:'Unknown Needs' }
							| 'NOT IMPL'
								res.status 501 .render 'error' { err:'Not Implemented'}
							| _
								res.status 500 .render 'error' { err:'There was an error... Where did it go...?' }
					else
						next!
			]
