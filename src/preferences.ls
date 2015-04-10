require! {
	"express"
}
app = express.Router()
app
	..route "/preferences"
	.all (req, res, next)->
		res.locals.needs = 1
		app.locals.authorize req, res, next
	.get (req, res, next)->
		res.render "preferences"

module.exports = app
