# api

watch-api:
	$(WATCH_SWIFT) '$(NX) run api:start'

build-api:
	$(NX) run api:build

test-api:
	$(NX) run api:test

migrate-up: build-api
	$(API_RUN) migrate --yes

migrate-down: build-api
	$(API_RUN) migrate --revert --yes

# gertieql

build-gertieql:
	$(NX) run gertieql:build

test-gertieql:
	$(NX) run gertieql:test

build-gql-dash:
	$(NX) run gql-dashboard:build

test-gql-dash:
	$(NX) run gql-dashboard:test

build-gql-macapp:
	$(NX) run gql-macos-app:build

test-gql-macapp:
	$(NX) run gql-macos-app:test

# shared

build-shared:
	$(NX) run shared:build

test-shared:
	$(NX) run shared:test

# duet

build-duet:
	$(NX) run duet:build

test-duet:
	$(NX) run duet:test

# x-kit

build-xkit:
	$(NX) run x-kit:build

test-xkit:
	$(NX) run x-kit:test

# root

build:
	$(NX) run-many --target=build

test:
	$(NX) run-many --target=test

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
	rm -rf x-kit/.build
	rm -rf shared/.build
	rm -rf gertieql/.build
	rm -rf gql-macos-app/.build
	rm -rf gql-dashboard/.build

# helpers

NX = node_modules/.bin/nx
WATCH_SWIFT = watchexec --restart --clear --watch . --exts swift
SWIFT_TEST = SWIFT_DETERMINISTIC_HASHING=1 swift test
API_RUN = cd api && ./.build/debug/Run
ALL_CMDS = api build-api migrate-up migrate-down \
  build-shared test-shared \
  build-gertieql test-gertieql \
  build-gql-dash test-gql-dash \
  build-gql-macapp test-gql-macapp \
  build-xkit test-xkit \
  build-duet test-duet \
	exclude clean test build check

.PHONY: $(ALL_CMDS)
.SILENT: $(ALL_CMDS)
