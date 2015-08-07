module.exports = (app,redishost,redisport,redisauth,redisdb)->
	require! {
		"ioredis"
		"winston"
	}
	/* istanbul ignore next this is all setup if/else's there is no way to get here after initial run */
	if redisauth?
		rediscli = new ioredis redisport, redishost, {
			password: redisauth
		}
	else
		rediscli = new ioredis redisport, redishost, {}
	rediscli.on "connect", ->
		winston.info "redis:connected"
		app.locals.redis = rediscli
		err <- rediscli.select redisdb
		/* istanbul ignore if */
		if err
			winston.error "redis:db", err
		else
			winston.info "redis:using db \##{redisdb}"
	rediscli.on "ready", ->
		winston.info "redis:ready"
	rediscli.on "error", ->
		winston.error it
	/* istanbul ignore next */
	rediscli.on "disconnect", ->
		winston.warn "redis:disconnected\ntrying to reconnect"
		rediscli.connect!
	return rediscli
