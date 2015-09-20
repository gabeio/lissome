require! {
	"express"
	"./app"
}
router = express.Router!
router
	..route "/"
	.all (req, res, next)->
		err <- req.session.destroy
		/* istanbul ignore if should only occur if weird db issue */
		winston.error "logout.ls: session.destroy", err if err?
		res.redirect "/login"

module.exports = router
