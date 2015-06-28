require! {
	"express"
	"./app"
}
router = express.Router!
router
	..route "/"
	.all (req, res, next)->
		err <- req.session.destroy
		res.redirect "/login"

module.exports = router
