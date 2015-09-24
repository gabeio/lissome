module.exports = (app)->
	require! {
		"async"
		"winston"
	}
	/* istanbul ignore next this literally catches all the errors hard to test */
	app
		..use (err, req, res, next)->
			/* istanbul ignore next this literally catches all the errors hard to test */
			async.parallel [
				!->
					# ALWAYS LOG
					winston.warn "error.ls: ", err, req.originalUrl
				!->
					if err?
						if err.code is "EBADCSRFTOKEN"
							res.status 403 .render "error" {err:"Bad Request"}
						else
							switch err.message
							| "NOT FOUND"
								res.status 404 .render "error" { err:"Not Found" }
							| "NOT XHR"
								res.status 400 .render "error" { err:"Not Sent Correctly" }
							| "UNAUTHORIZED"
								if res.locals.auth?
									res.status 302 .redirect "/" # logged in
								else
									res.status 302 .redirect "/login" # not logged in
								# res.status 401 .render "error" { err:"Unauthorized" }
							| "UNKNOWN NEEDS"
								res.status 401 .render "error" { err:"Unknown Needs" }
							| "NOT IMPL"
								res.status 501 .render "error" { err:"Not Implemented"}
							| "NO MORE ATTEMPTS ALLOWED"
								res.status 400 .render "error" { err:"You have submitted that max attempts allow for that assignment."}
							| _
								res.status 500 .render "error" { err:"There was an error... Where did it go...?" }
					else
						next!
			]
