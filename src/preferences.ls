require! {
	"express"
	"async"
	"lodash":"_"
	"mongoose"
	"winston"
	"./app"
}
ObjectId = mongoose.Types.ObjectId
User = mongoose.models.User
router = express.Router!
router
	..route "/:anything(*)?"
	.all (req, res, next)->
		res.locals.needs = 1
		app.locals.authorize req, res, next
	.all (req, res, next)->
		err, result <- User.findOne {
			_id:req.session.uid
			username:req.session.username
		}
		.exec
		if err
			winston.error "preferences.ls:user.findOne", err
			next new Error "MONGO"
		else
			res.locals.user = result
			next "route"
	..use "/otp", require("./preferences/otp")
	..use "/", require("./preferences/index")

module.exports = router
