module.exports = (app)->
	require! {
		"async"
		"lodash"
		"mongoose"
		"winston"
	}
	_ = lodash
	Course = mongoose.models.Course
	app
		..route "/:index(index|dash|dashboard)?"
		.all (req, res, next)->
			res.locals.needs = 1
			app.locals.authorize req, res, next
		.get (req, res, next)->
			res.locals.on = "dash"
			<- async.parallel [
				(done)->
					if res.locals.auth >= 3
						err, courses <- Course.find {
							"school":app.locals.school
						}
						/* istanbul ignore if */
						if err
							winston.error "course:find", err
							next new Error "INTERNAL"
						else
							res.locals.courses = courses
							done!
					else
						done!
				(done)->
					if res.locals.auth is 2
						err, courses <- Course.find {
							"school":app.locals.school
							"faculty":mongoose.Types.ObjectId(res.locals.uid)
						}
						/* istanbul ignore if */
						if err
							winston.error "course:find", err
							next new Error "INTERNAL"
						else
							res.locals.courses = courses
							done!
					else
						done!
				(done)->
					if res.locals.auth is 1
						err, courses <- Course.find {
							"school":app.locals.school
							"students":mongoose.Types.ObjectId(res.locals.uid)
						}
						/* istanbul ignore if */
						if err
							winston.error "course:find", err
							next new Error "INTERNAL"
						else
							res.locals.courses = courses
							done!
					else
						done!
			]
			res.render "dashboard"
