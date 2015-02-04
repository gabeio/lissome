module.exports = exports = (app)->
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
									res.redirect '/' # logged in
								else
									res.redirect '/login' # not logged in
								# res.status 401 .render 'error' { err:'Unauthorized' }
							| _
								res.status 500 .render 'error' { err:'There was an error... Where did it go...?' }
					else
						next!
			]
