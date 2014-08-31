start:
	foreman run coffee server.coffee

build:
	./node_modules/.bin/lessc --clean-css style.less ./assets/style.css
	NODE_ENV=production ./node_modules/.bin/browserify -t coffeeify ./ | uglifyjs -cm 2>/dev/null > ./assets/bundle.js

build-light:
	./node_modules/.bin/lessc style.less ./assets/style.css
	./node_modules/.bin/browserify -t coffeeify ./ > ./assets/bundle.js

start-prod:
	NODE_ENV=production coffee server.coffee

clean:
	rm -f ./assets/bundle.js

run:
	make build-light
	make start
