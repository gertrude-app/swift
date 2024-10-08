_default:
  @just --choose

# macapp

bump version:
  @node macapp/bump.mjs {{version}}

codegen-swift:
  @cd macapp/App && CODEGEN_SWIFT=1 swift test --filter Codegen
  @cd api && CODEGEN_SWIFT=1 swift test --filter Codegen

codegen-swift-unimplemented:
  @cd macapp/App && CODEGEN_SWIFT=1 CODEGEN_UNIMPLEMENTED=1 swift test --filter Codegen

codegen-typescript:
  @cd macapp/App && CODEGEN_TYPESCRIPT=1 swift test --filter Codegen

codegen: codegen-typescript codegen-swift

xcode:
  @open macapp/Xcode/Gertrude.xcodeproj

# ios

watch-ios:
  @just watch-build iosapp/lib-ios

# api

watch-api:
  @just watch-swift . 'just run-api' 'macapp/**/*'

run-api: build-api
	@just exec-api serve

run-api-ip: build-api
	@just exec-api serve --hostname 192.168.10.227

build-api:
	@cd api && swift build

migrate-up: build-api
	@just exec-api migrate --yes

migrate-down: build-api
	@just exec-api migrate --revert --yes

nuke-test-db:
  @killall -q Postico; dropdb --if-exists gertrude_test; createdb gertrude_test

#infra

db-sync:
	@node ../infra/db-sync.mjs

sync-env:
	@node ../infra/sync-env.mjs

# root

build:
	@just nx-run-many build

test:
	@just nx-run-many test

check:
	@just build
	@just test

exclude:
	@find . -path '**/.build/**/swift-nio*/**/hash.txt' -delete
	@find . -path '**/.build/**/swift-nio*/**/*_nasm.inc' -delete
	@find . -path '**/.build/**/swift-nio*/**/*_sha1.sh' -delete
	@find . -path '**/.build/**/swift-nio*/**/*_llhttp.sh' -delete
	@find . -path '**/.build/**/swift-nio*/**/LICENSE-MIT' -delete

nx-reset:
	@pnpm nx reset

clean: nx-reset
	@rm -rf node_modules/.cache
	@rm -rf api/.build
	@rm -rf duet/.build
	@rm -rf pairql/.build
	@rm -rf pairql-macapp/.build
	@rm -rf shared/.build
	@rm -rf x-kit/.build

clean-api-tests:
	@cd api && find .build -name '*AppTests*' -delete

# helpers

[private]
exec-api cmd *args:
  @cd api && ./.build/debug/Run {{cmd}} {{args}}

[private]
nx-run-many targets:
  @pnpm exec nx run-many --parallel=10 --targets={{targets}}

[private]
watch-swift dir cmd ignore1="•" ignore2="•" ignore3="•":
  @watchexec --project-origin . --clear --restart --watch {{dir}} --exts swift \
  --ignore '**/.build/*/**' --ignore '{{ignore1}}' --ignore '{{ignore2}}' --ignore '{{ignore3}}' \
  {{cmd}}

watch-build dir:
  @just watch-swift {{dir}} '"cd {{dir}} && swift build"'

watch-test dir isolate="":
  @just watch-swift {{dir}} '"cd {{dir}} && \
  SWIFT_DETERMINISTIC_HASHING=1 swift test \
  {{ if isolate != "" { "--filter " + isolate } else { "" } }} "'
