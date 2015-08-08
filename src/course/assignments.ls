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
	..route "/:action?" # query :: action(new|edit|delete|grade)
	.all (req, res, next)->
		# (default view)
		# find all assignments
		res.locals.assignments = {
			course: ObjectId res.locals.course._id
		}
		if res.locals.auth is 1
			res.locals.assignments.start = {
				"$lt": new Date Date.now!
			}
		err, result <- Assignment.find res.locals.assignments
		.populate "author"
		.sort { timestamp: -1 } # sort by date created
		.exec
		res.locals.assignments? = result
		next err
	.get (req, res, next)->
		async.parallel [
			(done)->
				if !req.params.action? && !req.params.assign?
					# show list of assignments by title
					res.render "course/assignments/default", { success: req.query.success, action: req.query.verb, csrf: req.csrfToken! }
			(done)->
				if req.params.action?
					next! # don't assume action, continue trying
		]
	.all (req, res, next)->
		# to modify assignments you need to be faculty+
		res.locals.needs = 2
		app.locals.authorize req, res, next
	### EVERYTHING AFTER HERE IS FACULTY+ ###
	.get (req, res, next)->
		switch req.params.action
		| "new"
			res.render "course/assignments/create", { csrf: req.csrfToken! }
		| _
			next! # don't assume action
	.post parser, (req, res, next)->
		switch req.params.action
		| "new" # handle new assignment
			async.parallel [
				(para)->
					if !req.body.title? or !req.body.text? or !req.body.tries? or req.body.title is "" or req.body.text is "" # double check require fields exists
						res.status 400 .render "course/assignments/create" { body: req.body, success:"no", action:"edit", csrf: req.csrfToken! }
				(para)->
					if req.body.title? and req.body.text? and req.body.tries? and req.body.title isnt "" and req.body.text isnt ""
						res.locals.start = new Date req.body.opendate+" "+req.body.opentime
						res.locals.end = new Date req.body.closedate+" "+req.body.closetime
						res.locals.assign = {
							title: req.body.title
							text: req.body.text
							start: res.locals.start
							end: res.locals.end
							tries: req.body.tries
							allowLate: if req.body.late is "yes" then true else false
							totalPoints: req.body.total
							# unchangeable
							author: ObjectId res.locals.uid
							course: res.locals.course._id
						}
						<- async.parallel [
							(para)->
								if !moment(res.locals.start).isValid!
									delete res.locals.assign.start
									para!
								else
									para!
							(para)->
								if !moment(res.locals.end).isValid!
									delete res.locals.assign.end
									para!
								else
									para!
						]
						assignment = new Assignment res.locals.assign
						err, assignment <- assignment.save
						/* istanbul ignore if should only occur if db crashes */
						if err?
							winston.error err
							next new Error "INTERNAL"
						else
							res.status 302 .redirect "/c/#{res.locals.course._id}/assignment/#{assignment._id}"
			]
		| _
			next! # don't assume action

module.exports = router
