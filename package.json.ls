name: "lissome"
version: "0.0.8a"

private: true

bugs: "https://github.com/gabeio/lissome/issues"

engines:
	node: ">= 0.10.0"
	iojs: ">= 1.0.0"

scripts:
	start: "node ./lib/app.js"
	build: "gulp build"
	clean: "gulp clean"
	test: "gulp clean && gulp build && gulp build-tests && mocha --slow 2"
	test-ci: "gulp clean && gulp build && gulp build-tests && istanbul cover ./node_modules/mocha/bin/_mocha --report lcovonly -- -s 2 -R spec"
	coverage: "gulp build && gulp build-tests && istanbul cover ./node_modules/mocha/bin/_mocha"
	continuous: "nodemon -w ./ -e html,css,js -x node ./lib/app.js"

repository:
	type: "git"
	url: "git://github.com/gabeio/lissome.git"

dependencies:
	"async": "~1.4.2"
	"bcrypt": "~0.8.5"
	"body-parser": "~1.13.3"
	"compression": "~1.5.2"
	"connect-redis": "~2.5.0"
	"cors": "~2.7.1"
	"csurf": "~1.8.3"
	"express": "~4.13.3"
	"express-partial-response": "~0.3.4"
	"express-session": "~1.11.3"
	"helmet": "~0.10.0"
	"ioredis": "~1.7.5"
	"livescript": "~1.4.0"
	"lodash": "~3.10.1"
	"markdown-it": "~4.4.0"
	"method-override": "~2.3.5"
	"moment": "~2.10.6"
	"moment-timezone": "~0.4.0"
	"mongoose": "~4.1.3"
	"multer": "~1.0.3"
	"passcode": "~1.0.2"
	"response-time": "~2.3.1"
	"request": "~2.61.0"
	"serve-static": "~1.10.0"
	"swig": "~1.4.2"
	"thirty-two": "~0.0.2"
	"winston": "~1.0.1"
	"yargs": "~3.21.0"

optionalDependencies:
	"hiredis": "~0.4.0"

devDependencies:
	"chai": "~3.2.0"
	"del": "~1.2.1"
	"gulp": "~3.9.0"
	"gulp-livescript": "~2.4.0"
	"istanbul": "~0.3.18"
	"mocha": "~2.2.5"
	"supertest": "~0.15.0"
