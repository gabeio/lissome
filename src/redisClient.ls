module.exports = (app,redishost,redisport,redisauth,redisdb)->
	require! {
		'redis'
		'winston'
	}
	/* istanbul ignore next this is all setup if/else's there is no way to get here after initial run */
	if redisauth?
		rediscli = redis.createClient redisport, redishost, {
			auth_pass: redisauth
		}
	else
		rediscli = redis.createClient redisport, redishost, {}
	rediscli.on "connect", ->
		winston.info "redis:connected"
		app.locals.redis = rediscli
		err <- rediscli.select redisdb
		/* istanbul ignore if */
		if err
			winston.info 'redis:db', err
		winston.info "using #{redisdb}"
	rediscli.on "ready", ->
		winston.info "redis:ready"
	/* istanbul ignore next */
	rediscli.on "disconnect", ->
		winston.warn 'redis:disconnected\ntrying to reconnect'
		rediscli.connect!
	return rediscli
