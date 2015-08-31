Lissome
=======

[![Build Status](https://magnum.travis-ci.com/gabeio/lissome.svg?token=8ysSVLsN3qoWuWWmeBwM&branch=develop)](https://magnum.travis-ci.com/gabeio/lissome)
[![Circle CI](https://circleci.com/gh/gabeio/lissome/tree/develop.svg?style=svg&circle-token=541ce6a9dc1d8fdbaad3c0f6ec11931485ec96cd)](https://circleci.com/gh/gabeio/lissome/tree/develop)
[![Dependency Status](https://gemnasium.com/feee31ec6a8bc2286a63441e57234d8f.svg)](https://gemnasium.com/gabeio/lissome)
[![Coverage Status](https://coveralls.io/repos/gabeio/lissome/badge.svg?branch=develop&t=blNPeE)](https://coveralls.io/r/gabeio/lissome?branch=develop)

## docker
- requires linked redis for sessions
- requires linked mongo for everything else

## process.env
- cookie = the session cookie signature assure this is safe or people can edit their sessions
- school = the school's full name or short name ie: OCC Ocean County College is a little big
- mongo|MONGO = the uri to mongodb (mongodb://[[username]:[password]]@host[:port]/dbName)
- redis|REDIS = the uri to redis (redis://[:password]@host:port/dbIndex)
- small|smallpassword = the minimum password length all passwords must be
- NODE_ENV=production = enables template caching
- NODE_ENV=development = disables template caching

## auth levels
- 0|undefined = outside
- 1 = student
- 2 = faculty
- 3 = admin
- + = superadmin/support
