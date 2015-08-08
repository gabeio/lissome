module.exports = (app,redis)->
	require! {
		"ioredis"
		"winston"
	}
	rediscli = new ioredis redis
	rediscli.on "connect", ->
		winston.info "redis: connected"
		app.locals.redis = rediscli
	rediscli.on "ready", ->
		winston.info "redis: ready"
	/* istanbul ignore next only occurs upon redis error */
	rediscli.on "error", ->
		winston.error it
	/* istanbul ignore next only occurs if redis disconnects */
	rediscli.on "disconnect", ->
		winston.warn "redis: disconnected trying to reconnect"
		rediscli.connect!
	return rediscli
