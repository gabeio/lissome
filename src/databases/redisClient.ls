module.exports = (app,redis)->
	require! {
		"ioredis"
		"winston"
	}
	rediscli = new ioredis redis
	rediscli.on "connect", ->
		winston.info "redis: connected"
		app.locals.redis = rediscli
		/* istanbul ignore if */
		if err
			winston.error "redis: db", err
		else
			winston.info "redis: using db \##{redisdb}"
	rediscli.on "ready", ->
		winston.info "redis: ready"
	/* istanbul ignore next only occurse upon redis error */
	rediscli.on "error", ->
		winston.error it
	/* istanbul ignore next */
	rediscli.on "disconnect", ->
		winston.warn "redis: disconnected trying to reconnect"
		rediscli.connect!
	return rediscli
