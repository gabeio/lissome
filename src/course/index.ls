require! {
	"express"
	"mongoose"
	"winston"
	"../app"
}
ObjectId = mongoose.Types.ObjectId
Post = mongoose.models.Post
router = express.Router!
router
	..route "/?:index(index|dash|dashboard)?"
	.get (req, res, next)->
		res.render "course/index"

module.exports = router
