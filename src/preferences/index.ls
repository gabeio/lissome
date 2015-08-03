require! {
	"express"
	"../app"
}
router = express.Router!
router
	..route "/"
	.get (req, res, next)->
		res.render "preferences/index"

module.exports = router
