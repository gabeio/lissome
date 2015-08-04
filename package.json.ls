name: "lissome"
version: "0.0.8"

private: true

bugs: "https://github.com/gabeio/lissome/issues"

engines:
	node: ">= 0.10.0"
	iojs: ">= 1.0.0"

scripts:
	start: "node ./lib/app.js"
	test: "gulp build && gulp build-tests && mocha --slow 2"
	test-ci: "gulp build && gulp build-tests && istanbul cover ./node_modules/mocha/bin/_mocha --report lcovonly -- -s 2 -R spec"
	coverage: "gulp build && gulp build-tests && istanbul cover ./node_modules/mocha/bin/_mocha"
	continuous: "nodemon -w ./ -e html,css,js -x node ./lib/app.js"

repository:
	type: "git"
	url: "git://github.com/gabeio/lissome.git"

dependencies:
	"async": "~1.4.0"
	"body-parser": "~1.13.3"
	"compression": "~1.5.2"
	"connect-redis": "~2.4.1"
	"cors": "~2.7.1"
	"csurf": "~1.8.3"
	"express": "~4.13.3"
	"express-partial-response": "~0.3.4"
	"express-session": "~1.11.3"
	"helmet": "~0.10.0"
	"ioredis": "~1.7.2"
	"livescript": "~1.4.0"
	"lodash": "~3.10.0"
	"markdown-it": "~4.4.0"
	"method-override": "~2.3.5"
	"moment": "~2.10.6"
	"moment-timezone": "~0.4.0"
	"mongoose": "~4.1.0"
	"multer": "~1.0.1"
	"passcode": "~1.0.2"
	"response-time": "~2.3.1"
	"request": "~2.60.0"
	"scrypt": "~4.0.7"
	"serve-static": "~1.10.0"
	"swig": "~1.4.2"
	"thirty-two": "~0.0.2"
	"winston": "~1.0.1"
	"yargs": "~3.17.1"

optionalDependencies:
	"hiredis": "~0.4.0"

devDependencies:
	"chai": "~3.2.0"
	"del": "~1.2.0"
	"gulp": "~3.9.0"
	"gulp-livescript": "~2.4.0"
	"istanbul": "~0.3.17"
	"mocha": "~2.2.5"
	"supertest": "~0.15.0"
