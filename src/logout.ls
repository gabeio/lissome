require! {
	"express"
}
app = express.Router()
app
	..route "/logout"
	.all (req, res, next)->
		err <- req.session.destroy
		res.redirect "/login"

module.exports = app
