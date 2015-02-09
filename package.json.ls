name: 'smrtboard'
version: '0.0.0a'

private: true

bugs: 'https://github.com/gabeio/smrtboard/issues'

engines:
	node: '>= 0.10.0'

scripts:
	start: 'node ./app.js'
	test: 'gulp run-tests'
	test-ci: 'gulp build && gulp build-tests && istanbul cover ./node_modules/mocha/bin/_mocha --report lcovonly -- -R spec && cat ./coverage/lcov.info | ./node_modules/coveralls/bin/coveralls.js && rm -rf ./coverage'
	test-cover: 'gulp build && gulp build-tests && istanbul cover ./node_modules/mocha/bin/_mocha --report lcovonly -- -R spec'
	continuousInstall: 'npm i nodemon; gulp build'
	continuous: 'nodemon -w ./ -e html,css,js -x node app.js'

repository:
	type: 'git'
	url: 'git://github.com/gabeio/smrtboard.git'

dependencies:
	"async": '~0.9.0'
	"bcrypt": '~0.8.1'
	"body-parser": '~1.11.0'
	"compression": '~1.4.0'
	"cookie-parser": '~1.3.3'
	"csurf": '~1.6.5'
	"express": '~4.11.1'
	"express-partial-response": '~0.3.4'
	"express-session": '~1.10.1'
	"fs-extra": '~0.16.3'
	"LiveScript": '~1.3.1'
	"lodash": '~3.1.0'
	"method-override": '~2.3.1'
	"mongoose": '~3.8.23'
	"multer": '~0.1.7'
	"request": '~2.53.0'
	"serve-static": '~1.8.0'
	"swig": '~1.4.2'
	"uuid": '~2.0.1'
	"winston": '~0.9.0'
	"yargs": '~1.3.3'

devDependencies:
	"chai": '~1.10.0'
	"coveralls": '~2.11.2'
	"del": '~1.1.1'
	"gulp": '~3.8.10'
	"gulp-coveralls": '~0.1.3'
	"gulp-livescript": '~2.3.0'
	"gulp-mocha": '~2.0.0'
	"istanbul": '~0.3.5'
	"mocha": '~2.1.0'
	"nodemon": '~1.3.1'
	"supertest": '~0.15.0'
