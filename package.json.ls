name: "lissome"
version: "0.0.10"

bugs: "https://github.com/gabeio/lissome/issues"

engines:
	node: ">= 0.10.0"
	iojs: ">= 1.0.0"

scripts:
	start: "node ./lib/app.js"
	build: "gulp build"
	clean: "gulp clean"
	test: "gulp clean && gulp build && gulp build-tests && mocha --exit --slow 2"
	test-ci: "gulp clean && gulp build && gulp build-tests && istanbul cover ./node_modules/mocha/bin/_mocha --report lcovonly -- --exit -s 2 -R spec"
	coverage: "gulp build && gulp build-tests && istanbul cover ./node_modules/mocha/bin/_mocha --exit"
	continuous: "nodemon -w ./ -e html,css,js -x node ./lib/app.js"

repository:
	type: "git"
	url: "git://github.com/gabeio/lissome.git"

dependencies:
	"async": "~2.6.0"
	"bcrypt": "~2.0.1"
	"body-parser": "~1.18.2"
	"compression": "~1.7.1"
	"connect-redis": "~3.3.3"
	"cors": "~2.8.0"
	"csurf": "~1.9.0"
	"express": "~4.16.0"
	"express-partial-response": "~0.3.4"
	"express-session": "~1.15.6"
	"helmet": "~3.12.0"
	"ioredis": "~3.2.0"
	"kerberos": "~0.0.21"
	"livescript": "~1.5.0"
	"lodash": "~4.17.10"
	"markdown-it": "~8.4.1"
	"method-override": "~2.3.10"
	"moment": "~2.22.0"
	"moment-timezone": "~0.5.0"
	"mongoose": "~4.13.13"
	"multer": "~1.3.0"
	"nunjucks": "~3.1.3"
	"passcode": "~1.0.2"
	"q": "~1.5.0"
	"response-time": "~2.3.1"
	"request": "~2.87.0"
	"serve-static": "~1.13.0"
	"thirty-two": "~1.0.2"
	"winston": "~2.4.2"
	"yargs": "~11.0.0"

optionalDependencies:
	"hiredis": "~0.5.0"

devDependencies:
	"chai": "~4.1.2"
	"del": "~3.0.0"
	"gulp": "~3.9.1"
	"gulp-livescript": "~3.0.0"
	"istanbul": "~0.4.0"
	"mocha": "~5.2.0"
	"supertest": "~3.1.0"
