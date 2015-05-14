name: 'lissome'
version: '0.0.3'

private: true

bugs: 'https://github.com/gabeio/lissome/issues'

engines:
	node: '>= 0.10.0'

scripts:
	start: 'node ./lib/app.js'
	test: 'gulp build && gulp build-tests && mocha'
	test-ci: 'gulp build && gulp build-tests && istanbul cover ./node_modules/mocha/bin/_mocha --report lcovonly -- -R spec && cat ./coverage/lcov.info | ./node_modules/coveralls/bin/coveralls.js && rm -rf ./coverage'
	coverage: 'gulp build && gulp build-tests && istanbul cover ./node_modules/mocha/bin/_mocha'
	continuous: 'nodemon -w ./ -e html,css,js -x node ./lib/app.js'

repository:
	type: 'git'
	url: 'git://github.com/gabeio/lissome.git'

dependencies:
	"async": '~0.9.0'
	"bcrypt": '~0.8.1'
	"body-parser": '~1.12.0'
	"compression": '~1.4.0'
	"connect-redis": '~2.3.0'
	"cookie-parser": '~1.3.4'
	"csurf": '~1.8.0'
	"express": '~4.12.2'
	"express-partial-response": '~0.3.4'
	"express-session": '~1.11.1'
	"fs-extra": '~0.18.0'
	"helmet": '~0.9.0'
	"hiredis": '~0.3.0'
	"livescript": '~1.4.0'
	"lodash": '~3.8.0'
	"markdown-it": '~4.2.0'
	"method-override": '~2.3.1'
	"moment": '~2.10.0'
	"moment-timezone": '~0.3.0'
	"mongoose": '~4.0.1'
	"multer": '~0.1.7'
	"redis": '~0.12.1'
	"request": '~2.55.0'
	"serve-static": '~1.9.1'
	"swig": '~1.4.2'
	"uuid": '~2.0.1'
	"winston": '~1.0.0'
	"yargs": '~3.9.0'

devDependencies:
	"chai": '~2.3.0'
	"coveralls": '~2.11.2'
	"del": '~1.1.1'
	"gulp": '~3.8.10'
	"gulp-coveralls": '~0.1.3'
	"gulp-livescript": '~2.3.0'
	"gulp-mocha": '~2.0.0'
	"istanbul": '~0.3.5'
	"mocha": '~2.2.1'
	"nodemon": '~1.3.1'
	"response-time": '~2.3.0'
	"supertest": '~0.15.0'
