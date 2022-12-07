# api

api:
	watchexec --restart --clear \
	  --watch api/Sources --watch api/Package.swift \
	  --watch gertieql/Sources --watch gertieql/Package.swift \
	  --watch shared/Sources --watch shared/Package.swift \
	  --exts swift \
	  'make build-api && make run-api'

build-api:
	cd api && swift build

run-api:
	$(API_RUN) serve --port 8082

test-api:
	cd api && $(SWIFT_TEST)

migrate-up: build-api
	$(API_RUN) migrate --yes

migrate-down: build-api
	$(API_RUN) migrate --revert --yes

# gertieql

gertieql:
	watchexec --restart --clear \
	  --watch gertieql/Sources \
	  --watch gertieql/Package.swift \
	  --exts swift \
	  'make build-gertieql'

build-gertieql:
	cd gertieql && swift build

test-gertieql:
	cd gertieql && $(SWIFT_TEST)

gql-dash:
	watchexec --restart --clear \
	  --watch gql-dashboard/Sources \
	  --watch gql-dashboard/Package.swift \
	  --exts swift \
	  'make build-gql-dash'

build-gql-dash:
	cd gql-dashboard && swift build

test-gql-dash:
	cd gql-dashboard && $(SWIFT_TEST)

gql-macapp:
	watchexec --restart --clear \
	  --watch gql-macos-app/Sources \
	  --watch gql-macos-app/Package.swift \
	  --exts swift \
	  'make build-gql-macapp'

build-gql-macapp:
	cd gql-macos-app && swift build

test-gql-macapp:
	cd gql-macos-app && $(SWIFT_TEST)

# shared

shared:
	watchexec --restart --clear \
	  --watch shared/Sources \
	  --watch shared/Package.swift \
	  --exts swift \
	  'make build-shared'

build-shared:
	cd shared && swift build

test-shared:
	cd shared && $(SWIFT_TEST)

# duet

duet:
	watchexec --restart --clear \
	  --watch duet/Sources \
	  --watch duet/Package.swift \
	  --exts swift \
	  'make build-duet'

build-duet:
	cd duet && swift build

test-duet:
	cd duet && $(SWIFT_TEST)

# x-kit

xkit:
	watchexec --restart --clear \
	  --watch duet/Sources \
	  --watch duet/Package.swift \
	  --exts swift \
	  'make build-xkit'

build-xkit:
	cd x-kit && swift build

test-xkit:
	cd x-kit && $(SWIFT_TEST)

# root

test:
	make test-shared
	make test-duet
	make test-xkit
	make test-gertieql
	make test-gql-dash
	make test-gql-macapp

build:
	make build-shared
	make build-duet
	make build-xkit
	make build-gertieql
	make build-gql-dash
	make build-gql-macapp

check:
	make build
	make test

exclude:
	find . -path '**/.build/**/swift-nio*/**/hash.txt' -delete
	find . -path '**/.build/**/swift-nio*/**/*_nasm.inc' -delete
	find . -path '**/.build/**/swift-nio*/**/*_sha1.sh' -delete
	find . -path '**/.build/**/swift-nio*/**/*_llhttp.sh' -delete
	find . -path '**/.build/**/swift-nio*/**/LICENSE-MIT' -delete

clean:
	rm -rf api/.build
	rm -rf duet/.build
	rm -rf x-kit/.build
	rm -rf shared/.build
	rm -rf gertieql/.build
	rm -rf gql-macos-app/.build
	rm -rf gql-dashboard/.build

# helpers

SWIFT_TEST = SWIFT_DETERMINISTIC_HASHING=1 swift test
API_RUN = cd api && ./.build/debug/Run
ALL_CMDS = api build-api run-api migrate-up migrate-down \
  shared build-shared test-shared \
  gertieql build-gertieql test-gertieql \
  gql-dash build-gql-dash test-gql-dash \
  gql-macapp build-gql-macapp test-gql-macapp \
  xkit build-xkit test-xkit \
  duet build-duet test-duet \
	exclude clean test build check

.PHONY: $(ALL_CMDS)
.SILENT: $(ALL_CMDS)
