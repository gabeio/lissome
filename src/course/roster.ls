require! {
	"express"
	"mongoose"
	"winston"
	"../app"
}
ObjectId = mongoose.Types.ObjectId
User = mongoose.models.User
router = express.Router!
router
	..route "/"
	.get (req, res, next)->
		res.render "course/roster"

module.exports = router
