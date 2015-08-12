require! {
	"express"
	"async"
	"lodash":"_"
	"moment"
	"mongoose"
	"winston"
	"../app"
}
parser = app.locals.multer.fields []
ObjectId = mongoose.Types.ObjectId
Assignment = mongoose.models.Assignment
Attempt = mongoose.models.Attempt
router = express.Router!
router
	..route /^\/(.{24})\/?(edit|delete|attempt)?$/i # query :: action(new|edit|delete|grade)
	.all (req, res, next)->
		req.params.assign = req.params.0
		req.params.action? = req.params.1
		err <- async.parallel [
			(done)->
				# get assignment
				err, result <- Assignment.findOne {
					course: ObjectId res.locals.course._id
					_id: ObjectId req.params.assign
				}
				.populate "author"
				.exec
				res.locals.assignment? = result
				done err
			(done)->
				# get attempts
				res.locals.attempts = {
					course: ObjectId res.locals.course._id
					assignment: ObjectId req.params.assign
				}
				if res.locals.auth is 1
					res.locals.attempts.author = ObjectId res.locals.uid
				err, results <- Attempt.find res.locals.attempts
				.populate "assignment"
				.populate "author"
				.sort { timestamp: -1 }
				.exec
				res.locals.attempts? = results
				done err
		]
		if err
			switch err
			| "fin"
				break
			| _
				winston.error "assignment.ls:", err
				next new Error err
		else if !res.locals.assignment?
			next new Error "NOT FOUND"
		else
			next!
	.get (req, res, next)->
		async.parallel [
			(done)->
				if !req.params.action? && req.params.assign?
					# show assignment details & attempt field
					res.render "course/assignments/view", { success: req.query.success, action: req.query.verb, csrf: req.csrfToken! }
			(done)->
				if req.params.action?
					next! # don't assume action, continue trying
		]
	.post parser, (req, res, next)->
		# handle new attempt
		switch req.params.action
		| "attempt"
			if !req.body.text?
				res.status 400 .render "course/assignments/view" { body: req.body, success:"error", error:"Attempt Text Can <b>not</b> be blank.", csrf: req.csrfToken! }
			else
				# find all tries related to user & assignment
				err, result <- Attempt.find {
					course: ObjectId res.locals.course._id
					author: ObjectId res.locals.uid
					assignment: ObjectId req.params.assign
				}
				.count!
				.exec
				res.locals.tries = result
				err <- async.parallel [
					(cont)->
						# date now gt start
						if (new Date Date.now!) > res.locals.assignment.start
							cont null
						else
							cont "Allowed assignment submission window has not opened."
					(cont)->
						# no end OR date now < end OR allowLate is true
						if !res.locals.assignment.end? or res.locals.assignment.end is "" or ((new Date Date.now!) < Date.parse(res.locals.assignment.end)) or (res.locals.assignment.allowLate is true)
							cont null
						else
							cont "Allowed assignment submission window has closed."
					(cont)->
						# only if my attempts are less than assignment tries create the new attempt
						if !res.locals.assignment.tries? or res.locals.assignment.tries > res.locals.tries
							cont null
						else
							cont "You have no more attempts."
				]
				if err
					res.status 400 .render "course/assignments/view" { body:req.body, success:"error", error:err, csrf: req.csrfToken! }
				else
					res.locals.body = {
						assignment: ObjectId req.params.assign
						course: ObjectId res.locals.course._id
						text: req.body.text
						author: ObjectId res.locals.uid
					}
					if res.locals.assignment.end? and (new Date Date.now!) > Date.parse(res.locals.assignment.end)
						res.locals.body.late = true
					res.locals.attempt = new Attempt res.locals.body
					err, attempt <- res.locals.attempt.save
					/* istanbul ignore if should only occur if db crashes */
					if err
						winston.error err
						next new Error "Mongo Error"
					else
						res.redirect "/c/#{res.locals.course._id}/attempt/#{attempt._id.toString!}"
		| _
			next! # not an attempt
	.all (req, res, next)->
		# to modify assignments you need to be faculty+
		res.locals.needs = 2
		app.locals.authorize req, res, next
	### EVERYTHING AFTER HERE IS FACULTY+ ###
	.get (req, res, next)->
		switch req.params.action
		| "edit"
			res.render "course/assignments/edit", { csrf: req.csrfToken! }
		| "delete"
			res.render "course/assignments/del", { csrf: req.csrfToken! }
		| _
			next! # don't assume action
	.put parser, (req, res, next)->
		# handle edit assignment
		switch req.params.action
		| "edit"
			if !req.body.title? || !req.body.text? || !req.body.tries? || req.body.title is "" || req.body.text is "" # double check require fields exist
				res.status 400 .render "course/assignments/edit" { body: req.body, success:"no", action:"edit", csrf: req.csrfToken! }
			else
				res.locals.start = new Date(req.body.opendate+" "+req.body.opentime)
				res.locals.end = new Date(req.body.closedate+" "+req.body.closetime)
				assign = {
					title: req.body.title
					text: req.body.text
					start: res.locals.start
					end: res.locals.end
					tries: req.body.tries
					allowLate: if req.body.late is "yes" then true else false
					totalPoints: req.body.total
				}
				if !req.body.total? or req.body.total is ""
					delete assign.totalPoints
				if !moment(res.locals.start).isValid!
					delete assign.start
				if res.locals.assignment.end? and ( !req.body.closedate? or req.body.closedate is "" )
					assign.end = "" # delete it if it already exists
				else if !moment(res.locals.end).isValid!
					delete assign.end
				err, assign <- Assignment.findOneAndUpdate {
					"_id": ObjectId req.params.assign
					"course": ObjectId res.locals.course._id
					# don't check for author as me might not be...
				}, assign
				/* istanbul ignore if should only occur if db crashes */
				if err?
					winston.error err
					next new Error "Mongo Error"
				else
					res.redirect "/c/#{res.locals.course._id}/assignment/#{assign._id.toString!}"
		| _
			next! # don't assume action
	.delete parser, (req, res, next)->
		# handle delete assignment (faculty+)
		switch req.params.action
		| "delete"
			err <- async.parallel [
				(done)->
					err, attempts <- Attempt.remove {
						"assignment": ObjectId req.params.assign
						"course": ObjectId res.locals.course._id
					}
					done err
				(done)->
					err, assignments <- Assignment.remove {
						"_id": ObjectId req.params.assign
						"course": ObjectId res.locals.course._id
					}
					done err
				(done)->
					res.status 302
					res.redirect "/c/#{res.locals.course._id}/assignments?success=yes"
			]
			winston.error "assignment.ls:", err if err
		| _
			next! # don't assume action

module.exports = router
