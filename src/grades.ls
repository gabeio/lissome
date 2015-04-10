require! {
	"express"
}
app = express.Router()
require! {
	"async"
	"mongoose"
	"winston"
}
ObjectId = mongoose.Types.ObjectId
Course = mongoose.models.Course
Assignment = mongoose.models.Assignment
Attempt = mongoose.models.Attempt

app
	..route "/"
	.all (req, res, next)->
		res.locals.needs = 1
		next!
	.all (req, res, next)->
		if res.locals.auth? and res.locals.needs? and res.locals.needs <= res.locals.auth
			next!
		else
			next new Error "UNAUTHORIZED"
	.all (req, res, next)->
		err, result <- Attempt.find {
			course: ObjectId res.locals.course._id
			author: ObjectId res.locals.uid
		}
		.populate "assignment"
		.populate "author"
		.sort!
		.exec
		if err?
			winston.error "assign findOne conf", err
			next new Error "INTERNAL"
		else
			res.locals.attempts = result
			next!
	.get (req, res, next)->
		res.render "grades"

module.exports = app
