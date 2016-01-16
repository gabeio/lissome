require! {
	"ioredis"
	"winston"
	"yargs"
}

/* istanbul ignore next */
redis = new ioredis (process.env.redis||process.env.REDIS||yargs.argv.redis||"redis://localhost:6379/0")
redis.on "connect", ->
	winston.info "redis: connected"
redis.on "ready", ->
	winston.info "redis: ready"
redis.on "error", winston.error.bind winston, "redis: connection error"

module.exports = redis
