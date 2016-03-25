Lissome
=======

[![Build Status](https://travis-ci.org/gabeio/lissome.svg?branch=develop)](https://travis-ci.org/gabeio/lissome)
[![Circle CI](https://circleci.com/gh/gabeio/lissome/tree/develop.svg?style=svg)](https://circleci.com/gh/gabeio/lissome/tree/develop)
[![Coverage Status](https://coveralls.io/repos/gabeio/lissome/badge.svg?branch=develop&t=blNPeE)](https://coveralls.io/r/gabeio/lissome?branch=develop)

[![Dependency Status](https://david-dm.org/gabeio/lissome.svg)](https://david-dm.org/gabeio/lissome)
[![devDependency Status](https://david-dm.org/gabeio/lissome/dev-status.svg)](https://david-dm.org/gabeio/lissome#info=devDependencies)
[![optionalDependency Status](https://david-dm.org/gabeio/lissome/optional-status.svg)](https://david-dm.org/gabeio/lissome#info=optionalDependencies)


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
