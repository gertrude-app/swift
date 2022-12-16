# api

watch-api:
	$(WATCH_SWIFT) 'cd api && swift build && ./.build/debug/Run serve --port 8082'

build-api:
	$(NX) run api:build

test-api:
	$(NX) run api:test

migrate-up: build-api
	$(API_RUN) migrate --yes

migrate-down: build-api
	$(API_RUN) migrate --revert --yes

# pairql

build-pql:
	$(NX) run pairql:build

test-pql:
	$(NX) run pairql:test

build-pql-dash:
	$(NX) run pairql-dash:build

test-pql-dash:
	$(NX) run pairql-dash:test

build-pql-macapp:
	$(NX) run pairql-macapp:build

test-pql-macapp:
	$(NX) run pairql-macapp:test

build-pql-ts:
	$(NX) run pairql-ts:build

test-pql-ts:
	$(NX) run pairql-ts:test

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

# x-*

build-xkit:
	$(NX) run x-kit:build

test-xkit:
	$(NX) run x-kit:test

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
	rm -rf pairql-dash/.build
	rm -rf pairql-macapp/.build
	rm -rf pairql-typescript/.build
	rm -rf shared/.build
	rm -rf x-kit/.build

# helpers

NX = node_modules/.bin/nx
WATCH_SWIFT = watchexec --restart --clear --watch . --exts swift
SWIFT_TEST = SWIFT_DETERMINISTIC_HASHING=1 swift test
API_RUN = cd api && ./.build/debug/Run
ALL_CMDS = api build-api migrate-up migrate-down \
  build-shared test-shared \
  build-pql test-pql \
  build-pql-dash test-pql-dash \
  build-pql-macapp test-pql-macapp \
  build-xkit test-xkit \
  build-duet test-duet \
	exclude clean test build check

.PHONY: $(ALL_CMDS)
.SILENT: $(ALL_CMDS)
