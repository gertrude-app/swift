# api

watch-api:
	$(WATCH_SWIFT) 'make run-api'

run-api: build-api
	$(API_RUN) serve --port 8080

run-api-ip: build-api
	$(API_RUN) serve --port 8080 --hostname 192.168.10.227

build-api:
	cd api && swift build

migrate-up: build-api
	$(API_RUN) migrate --yes

migrate-down: build-api
	$(API_RUN) migrate --revert --yes

#infra

deploy-prod:
	node ./api/Infra/deploy.mjs --production

deploy-staging:
	node ./api/Infra/deploy.mjs

deploy-all:
	make deploy-staging
	make deploy-prod

db-sync:
	node ./api/Infra/db-sync.mjs

# root

build:
	$(NX) run-many --target=build --parallel=10

test:
	$(NX) run-many --target=test --parallel=10

check:
	make build
	make test

exclude:
	find . -path '**/.build/**/swift-nio*/**/hash.txt' -delete
	find . -path '**/.build/**/swift-nio*/**/*_nasm.inc' -delete
	find . -path '**/.build/**/swift-nio*/**/*_sha1.sh' -delete
	find . -path '**/.build/**/swift-nio*/**/*_llhttp.sh' -delete
	find . -path '**/.build/**/swift-nio*/**/LICENSE-MIT' -delete

nx-reset:
	$(NX) reset

clean: nx-reset
	rm -rf node_modules/.cache
	rm -rf api/.build
	rm -rf duet/.build
	rm -rf pairql/.build
	rm -rf pairql-macapp/.build
	rm -rf pairql-typescript/.build
	rm -rf shared/.build
	rm -rf x-kit/.build

clean-api-tests:
	cd api && find .build -name '*AppTests*' -delete

# helpers

NX = node_modules/.bin/nx
WATCH_SWIFT = watchexec --project-origin . --clear --restart --watch . --exts swift --ignore '**/ApiKeys.swift' --ignore '**/.build/*/**/*'
SWIFT_TEST = SWIFT_DETERMINISTIC_HASHING=1 swift test
API_RUN = cd api && ./.build/debug/Run
ALL_CMDS = api watch-api run-api run-api-ip build-api migrate-up migrate-down \
	deploy-prod deploy-staging deploy-all db-sync \
	exclude clean test build check nx-reset clean-api-tests

.PHONY: $(ALL_CMDS)
.SILENT: $(ALL_CMDS)
