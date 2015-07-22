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
	.get (req, res, next)->
		res.render "preferences"

module.exports = router
