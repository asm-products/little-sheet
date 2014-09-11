start:
	foreman run coffee server.coffee

build:
	./node_modules/.bin/lessc --clean-css style.less ./assets/style.css
	npm run build

build-light:
	./node_modules/.bin/lessc style.less ./assets/style.css
	npm run build-light

start-prod:
	npm run start-prod

clean:
	rm -f ./assets/bundle.js

run:
	make build-light
	make start
