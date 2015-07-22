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
	..route "/"
	.all (req, res, next)->
		res.locals.needs = 1
		app.locals.authorize req, res, next
	.all (req, res, next)->
		err, result <- User.findOne {
			_id:req.session._id
			uid:req.session.uid
		}
		.exec
		if err
			winston.error "preferences.ls:user.findOne", err
		else
			res.locals.user = result
			next!
	.get (req, res, next)->
		res.render "preferences"

module.exports = router
