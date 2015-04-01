Lissome
=======

[![Codeship Status for gabeio/lissome](https://codeship.com/projects/c39d9310-a813-0132-0b5b-32b415211618/status?branch=develop)](https://codeship.com/projects/67317)
[![Build Status](https://magnum.travis-ci.com/gabeio/lissome.svg?token=8ysSVLsN3qoWuWWmeBwM&branch=develop)](https://magnum.travis-ci.com/gabeio/lissome)
[![Dependency Status](https://gemnasium.com/feee31ec6a8bc2286a63441e57234d8f.svg)](https://gemnasium.com/gabeio/lissome)
[![Coverage Status](https://coveralls.io/repos/gabeio/lissome/badge.svg?branch=develop&t=blNPeE)](https://coveralls.io/r/gabeio/lissome?branch=develop)

NODE_ENV
========
- production = turn on template caching

process.env
===========
- cookie = the session cookie signature assure this is safe or people can edit their sessions
- school = the school's full name or short name ie: OCC Ocean County College is a little big
- mongo|MONGOURL = the uri to mongodb (mongodb://[Username]:[Password]@HostName/DataBaseName)
- redishost|REDISHOST = the redis host
- redisport|REDISPORT = the port redis is running on
- redisauth|REDISAUTH = the auth for redis
- redisdb|REDISDB = the db index redis connects to

auth levels
===========
- 0|undefined = outside
- 1 = student
- 2 = faculty
- 3 = admin
