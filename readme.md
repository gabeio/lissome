Smrtboard
=======

[![Build Status](https://magnum.travis-ci.com/gabeio/smrtboard.svg?token=8ysSVLsN3qoWuWWmeBwM)](https://magnum.travis-ci.com/gabeio/smrtboard)
[![Dependency Status](https://gemnasium.com/20669af5ef14f415a6403154eba8562b.svg)](https://gemnasium.com/gabeio/smrtboard)

process.env
===========
- cookie = the session cookie signature assure this is safe or people can edit their sessions
- school = the school's full name or short name ie: OCC Ocean County College is a little big
- mongo|MONGOURL = the uri to mongodb (mongodb://LOCATION/DB)
- mongouser|MONGOUSER = the username to the mongo db
- mongopass|MONGOPASS = the password to the mongo db

auth levels
===========
- 0|undefined = outside
- 1 = student
- 2 = faculty
- 3 = admin
- 4 = su|root
- 5 = support needed.
