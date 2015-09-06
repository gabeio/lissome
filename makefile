build:
	npm i
	gulp build

test:
	gulp build
	gulp build-tests
	./node_modules/.bin/mocha --slow 2

coverage:
	gulp build
	gulp build-tests
	./node_modules/.bin/istanbul cover ./node_modules/mocha/bin/_mocha

clean:
	rm -rf ./lib/

.PHONY: default test coverage
