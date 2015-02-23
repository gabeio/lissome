Smrtboard
=======

[![Build Status](https://magnum.travis-ci.com/gabeio/smrtboard.svg?token=8ysSVLsN3qoWuWWmeBwM&branch=develop)](https://magnum.travis-ci.com/gabeio/smrtboard)
[![Dependency Status](https://gemnasium.com/feee31ec6a8bc2286a63441e57234d8f.svg)](https://gemnasium.com/gabeio/lissome)
[![Coverage Status](https://coveralls.io/repos/gabeio/smrtboard/badge.svg?branch=develop)](https://coveralls.io/r/gabeio/smrtboard?branch=develop)

process.env
===========
- cookie = the session cookie signature assure this is safe or people can edit their sessions
- school = the school's full name or short name ie: OCC Ocean County College is a little big
- mongo|MONGOURL = the uri to mongodb (mongodb://LOCATION/DB)
- mongouser|MONGOUSER = the username to the mongo db
- mongopass|MONGOPASS = the password to the mongo db
- redishost|REDISHOST = the redis host
- redisport|REDISPORT = the port redis is running on
- redisauth|REDISAUTH = the auth for redis

auth levels
===========
- 0|undefined = outside
- 1 = student
- 2 = faculty
- 3 = admin
- 4 = su|root
- 5 = support needed.
