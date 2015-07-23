require! {
	"express"
	"mongoose"
	"passcode"
	"winston"
	"../app"
}
User = mongoose.models.User
router = express.Router!
router
	..route "/"
	.get (req, res, next)->
		res.render "preferences/otp"

module.exports = router
