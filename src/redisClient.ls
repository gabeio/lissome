module.exports = (app,redishost,redisport,redisauth)->
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
	rediscli.on "open", ->
		winston.info "redis:open"
	rediscli.on "connect", ->
		winston.info "redis:connected"
		app.locals.redis = rediscli
	rediscli.on "ready", ->
		winston.info "redis:ready"
	rediscli.on "disconnect", ->
		winston.warn 'mongo:disconnect\ntrying to reconnect'
		rediscli.connect!
	return rediscli
