require! {
	"express"
}
app = express.Router()

app
	..route "/:index(index|dash|dashboard)?"
	.get (req, res, next)->
		console.log 'courseDash.ls res.locals', res.locals
		res.render "course"

module.exports = app
