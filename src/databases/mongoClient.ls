module.exports = (app,mongoose,mongouri)->
	require! {
		"winston"
	}
	mongo = mongoose.connection # create connection object
	mongo.options = {
		server:{
			keepAlive: 1
			poolSize: 7
		}
	}
	/* istanbul ignore next this is all setup if/else's there is no way to get here after initial run */
	mongo.open mongouri
	/* istanbul ignore next */
	mongo.on "disconnect", ->
		winston.warn "mongo:disconnected\ntrying to reconnect"
		mongo.connect!
	/* istanbul ignore next */
	# mongo.on "error" (err)->
	# 	winston.error err
	mongo.on "error", winston.error.bind winston, "mongo: connection error"
	mongo.on "open", winston.info.bind winston, "mongo: connection open"
	# mongo.on "open" (err)->
	# 	/* istanbul ignore if */
	# 	if err
	# 		winston.error "mongo:err: " + err
	# 	else
	# 		winston.info "mongo:open"
	# if app.locals.testing is true
	app.locals.mongo = mongo # save connection object in app level variables
	return mongo
