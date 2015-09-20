require! {
	"mongoose"
	"winston"
	"yargs"
}

mongo = mongoose.connection # create connection object
mongo.options = {
	server:{
		keepAlive: 1
		poolSize: 7
	}
}
/* istanbul ignore next */
mongo.open (process.env.mongo||process.env.MONGO||yargs.argv.mongo||"mongodb://localhost/lissome")
mongo.on "error", winston.error.bind winston, "mongo: connection error"
mongo.on "open", winston.info.bind winston, "mongo: connection open"
mongo.once "open" ->
	require! "./schemas"

module.exports = mongo
