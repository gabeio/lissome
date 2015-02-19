name: 'smrtboard'
version: '0.0.0a'

private: true

bugs: 'https://github.com/gabeio/smrtboard/issues'

engines:
	node: '>= 0.10.0'

scripts:
	start: 'node ./lib/app.js'
	test: 'gulp run-tests'
	test-ci: 'gulp build && gulp build-tests && istanbul cover ./node_modules/mocha/bin/_mocha --report lcovonly -- -R spec && cat ./coverage/lcov.info | ./node_modules/coveralls/bin/coveralls.js && rm -rf ./coverage'
	test-cover: 'gulp build && gulp build-tests && istanbul cover ./node_modules/mocha/bin/_mocha -- -R spec'
	continuous: 'nodemon -w ./ -e html,css,js -x node ./lib/app.js'

repository:
	type: 'git'
	url: 'git://github.com/gabeio/smrtboard.git'

dependencies:
	"async": '~0.9.0'
	"bcrypt": '~0.8.1'
	"body-parser": '~1.11.0'
	"compression": '~1.4.0'
	"connect-redis": '~2.2.0'
	"cookie-parser": '~1.3.4'
	"csurf": '~1.7.0'
	"express": '~4.11.2'
	"express-partial-response": '~0.3.4'
	"express-session": '~1.10.3'
	"fs-extra": '~0.16.3'
	"hiredis": '~0.2.0'
	"LiveScript": '~1.3.1'
	"lodash": '~3.2.0'
	"markdown": '~0.5.0'
	"method-override": '~2.3.1'
	"mongoose": '~3.8.23'
	"multer": '~0.1.7'
	"redis": '~0.12.1'
	"request": '~2.53.0'
	"serve-static": '~1.8.0'
	"swig": '~1.4.2'
	"uuid": '~2.0.1'
	"winston": '~0.9.0'
	"yargs": '~2.3.0'

devDependencies:
	"chai": '~2.0.0'
	"coveralls": '~2.11.2'
	"del": '~1.1.1'
	"gulp": '~3.8.10'
	"gulp-coveralls": '~0.1.3'
	"gulp-livescript": '~2.3.0'
	"gulp-mocha": '~2.0.0'
	"istanbul": '~0.3.5'
	"mocha": '~2.1.0'
	"nodemon": '~1.3.1'
	"response-time": '~2.2.0'
	"supertest": '~0.15.0'
