require! {
	"express"
	"../app"
}
router = express.Router!
router
	..route "/"
	.get (req, res, next)->
		res.render "course/roster"

module.exports = router
