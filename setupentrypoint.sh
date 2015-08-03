#!/bin/bash
export mongo="mongodb://${MONGO_PORT_27017_TCP_ADDR}:${MONGO_PORT_27017_TCP_PORT}/lissome"
export redishost="${REDIS_PORT_6379_TCP_ADDR}"
export redisport="${REDIS_PORT_6379_TCP_PORT}"
iojs lib/commandline/setupschool.js
