build:
	gulp build

test:
	gulp build
	gulp build-tests
	./node_modules/.bin/mocha

coverage:
	./node_modules/.bin/istanbul cover ./node_modules/mocha/bin/_mocha

.PHONY: test coverage
