require! {
	"express"
	"./app"
}
router = express.Router!
router
	..route "/"
	.all (req, res, next)->
		if !req.session? or !req.session.uid? or !req.session.userid? or !req.session.username?
			res.render "noCookie"
		else
			res.redirect req.query.to

module.exports = router
