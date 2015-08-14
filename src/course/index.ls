require! {
	"express"
	"../app"
}
router = express.Router!
router
	..route "/:index(index|dash|dashboard)?"
	.get (req, res, next)->
		res.render "course/index"

module.exports = router
