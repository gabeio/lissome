name: 'smrtboard'
version: '0.0.0a'

private: true

bugs: 'https://github.com/gabeio/smrtboard/issues'

engines:
	node: '>= 0.10.0'

scripts:
	start: 'export PORT=8080; lsc ./src/app.ls'
	test: 'gulp test'
	test-travis: 'istanbul cover gulp test -- --check-leaks test/'
	continuousInstall: 'npm i nodemon; gulp build'
	continuous: 'nodemon -w ./ -e html,css,js -x node app.js'

repository:
	type: 'git'
	url: 'git://github.com/gabeio/smrtboard.git'

dependencies:
	"async": '~0.9.0'
	"bcrypt": '~0.8.0'
	"body-parser": '~1.10.1'
	"compression": '~1.3.0'
	"cookie-parser": '~1.3.3'
	"csurf": '~1.6.5'
	"express": '~4.11.1'
	"express-partial-response": '~0.3.4'
	"express-session": '~1.10.1'
	"fs-extra": '~0.12.0'
	"gulp": '~3.8.10'
	"gulp-istanbul": '~0.5.0'
	"gulp-livescript": '~2.3.0'
	"gulp-mocha": '~2.0.0'
	"gulp-uglify": '~1.1.0'
	"leveldown": '~1.0.0'
	"levelup": '~0.19.0'
	"LiveScript": '~1.3.1'
	"lodash": '~2.4.1'
	"method-override": '~2.3.1'
	"multer": '~0.1.7'
	"request": '~2.51.0'
	"serve-static": '~1.8.0'
	"swig": '~1.4.2'
	"winston": '~0.8.3'
	"yargs": '~1.3.3'

devDependencies:
	"chai": '~1.10.0'
	"codeclimate-test-reporter": '~0.0.4'
	"del": '~1.1.1'
	"istanbul": '~0.3.5'
	"mocha": '~2.1.0'
	"nodemon": '~1.3.1'
	"supertest": '~0.15.0'