start:
	foreman run coffee server.coffee

build:
	npm run build

build-light:
	npm run build-light

start-prod:
	npm run start-prod

clean:
	rm -f ./assets/bundle.js

run:
	make build-light
	make start
