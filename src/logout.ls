require! {
	"express"
	"./app"
}
router = express.Router!
router
	..route "/"
	.all (req, res, next)->
		err <- req.session.destroy
		if err? then winston.error err
		res.redirect "/login"

module.exports = router
