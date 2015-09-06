#!/bin/bash
export mongo="mongodb://${MONGO_PORT_27017_TCP_ADDR}:${MONGO_PORT_27017_TCP_PORT}/lissome"
export redis="redis://${REDIS_PORT_6379_TCP_ADDR}:${REDIS_PORT_6379_TCP_PORT}/0"
iojs lib/commandline/setupschool.js
