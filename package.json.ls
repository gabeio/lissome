name: 'lissome'
version: '0.0.3'

private: true

bugs: 'https://github.com/gabeio/lissome/issues'

engines:
	node: '>= 0.10.0'

scripts:
	start: 'node ./lib/app.js'
	test: 'gulp build && gulp build-tests && mocha'
	test-ci: 'gulp build && gulp build-tests && istanbul cover ./node_modules/mocha/bin/_mocha --report lcovonly -- -R spec'
	coverage: 'gulp build && gulp build-tests && istanbul cover ./node_modules/mocha/bin/_mocha'
	continuous: 'nodemon -w ./ -e html,css,js -x node ./lib/app.js'

repository:
	type: 'git'
	url: 'git://github.com/gabeio/lissome.git'

dependencies:
	"async": '~1.2.1'
	"bcrypt": '~0.8.3'
	"body-parser": '~1.13.0'
	"compression": '~1.5.0'
	"connect-redis": '~2.3.0'
	"cors":"~2.7.1"
	"csurf": '~1.8.3'
	"express": '~4.12.4'
	"express-partial-response": '~0.3.4'
	"express-session": '~1.11.3'
	"helmet": '~0.9.1'
	"hiredis": '~0.4.0'
	"livescript": '~1.4.0'
	"lodash": '~3.9.3'
	"markdown-it": '~4.2.2'
	"method-override": '~2.3.3'
	"moment": '~2.10.3'
	"moment-timezone": '~0.4.0'
	"mongoose": '~4.0.5'
	"multer": '~0.1.8'
	"redis": '~0.12.1'
	"response-time": '~2.3.1'
	"serve-static": '~1.9.3'
	"swig": '~1.4.2'
	"uuid": '~2.0.1'
	"winston": '~1.0.0'
	"yargs": '~3.11.0'

devDependencies:
	"chai": '~3.0.0'
	"coveralls": '~2.11.2'
	"del": '~1.2.0'
	"gulp": '~3.9.0'
	"gulp-coveralls": '~0.1.4'
	"gulp-livescript": '~2.4.0'
	"gulp-mocha": '~2.1.1'
	"istanbul": '~0.3.15'
	"mocha": '~2.2.5'
	"nodemon": '~1.3.7'
	"supertest": '~0.15.0'
