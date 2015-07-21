require! {
	"express"
	"mongoose"
	#"winston"
	"../app"
}
parser = app.locals.multer.fields []
ObjectId = mongoose.Types.ObjectId
Course = mongoose.models.Course
router = express.Router!
router
	..route "/"
	.all (req, res, next)->
		res.locals.needs = 2
		app.locals.authorize req, res, next
	.get (req, res, next)->
		res.render "course/settings", { success: req.query.success, noun: "Defaults", verb: "updated", csrf: req.csrfToken! }
	.put parser, (req, res, next)->
		res.locals.course.settings = {
			assignments:{
				tries: req.body.tries
				allowLate: if req.body.late is "yes" then true else false
				totalPoints: req.body.total
				anonymousGrading: if req.body.anonymous is "yes" then true else false
			}
		}
		res.locals.course.settings.set("assignments","changed")
		err, result <- res.locals.course.save!
		if err?
			winston.error err
			next new Error "MONGO"
		else
			res.redirect "?success=yes"

module.exports = router
