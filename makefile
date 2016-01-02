build:
	npm i
	gulp build
	rm -rf ./node_modules/
	npm i

test:
	gulp build
	gulp build-tests
	./node_modules/.bin/mocha --slow 2

coverage:
	gulp build
	gulp build-tests
	./node_modules/.bin/istanbul cover ./node_modules/mocha/bin/_mocha

clean:
	rm -rf ./lib/ ./node_modules/

.PHONY: default build test coverage clean
