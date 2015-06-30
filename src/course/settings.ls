require! {
	"express"
	"mongoose"
	"winston"
	"../app"
}
ObjectId = mongoose.Types.ObjectId
Course = mongoose.models.Course
Post = mongoose.models.Post
router = express.Router!
router
	/* istanbul ignore next until is actually created */
	..route "/:course/settings"
	.all (req, res, next)->
		res.locals.needs = 2 # maybe 3
		app.locals.authorize req, res, next
	.all (req, res, next)->
		res.locals.on = "course"
		...
	.get (req, res, next)->
		res.send "this will allow showing of course settings"
		/*
		err,result <- Course.find { "id":req.params.course, "school":app.locals.school }
		if err?
			winston.error err
		if !result[0]?
			next new Error "NOT FOUND"
		else
			res.send result
		*/
	.post (req, res, next)->
		next new Error "NOT IMPL"
		/*
		err,result <- Course.update { "id":req.params.course, "school":app.locals.school }, {}
		if err?
			winston.error err
		if !result[0]?
			next new Error "NOT FOUND"
		else
			res.send result
		*/

module.exports = router
