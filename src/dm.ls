require! {
	"express"
	"async"
	"lodash"
	"mongoose"
	"winston"
	"../app"
}
ObjectId = mongoose.Types.ObjectId
_ = lodash
User = mongoose.models.User
router = express.Router!
router
	..route "/dm/:id?"
	.all (req, res, next)->
		res.locals.needs = 1
		app.locals.authorize req, res, next
	.get (req, res, next)->
		res.render "dm"

module.exports = router
