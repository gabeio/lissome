module.exports = (app,mongohost,mongouser,mongopass)->
	require! {
		"mongoose"
		"winston"
	}
	mongo = mongoose.connection # create connection object
	mongo.options = {
		server:{
			keepAlive: 1
			poolSize: 6
		}
	}
	/* istanbul ignore next this is all setup if/else"s there is no way to get here after initial run */
	if mongouser? && mongopass? # if there is auth
		mongo.open mongohost, { "user": mongouser, "pass": mongopass }
	else
		mongo.open mongohost
	/* istanbul ignore next */
	mongo.on "disconnect", ->
		winston.warn "mongo:disconnect\ntrying to reconnect"
		mongo.connect!
	/* istanbul ignore next */
	mongo.on "error", console.error.bind console, "connection error:"
	mongo.on "open" (err)->
		/* istanbul ignore if */
		if err
			winston.info "mongo:err: " + err
		winston.info "mongo:open"
	# if app.locals.testing is true
	app.locals.mongo = mongo # save connection object in app level variables
	return mongo
