_default:
  @just --choose

# macapp (rewrite)

watch-macapp pkg="App":
  @just watch-swift rewrite/{{pkg}} 'just build-macapp {{pkg}}'

build-macapp pkg="App":
  @cd rewrite/{{pkg}} && swift build

codegen-appviews:
  @cd rewrite/App && \
  CODEGEN_APPVIEWS=true CODEGEN_WEB_DIR=$CODEGEN_WEB_DIR \
  swift test --filter AppCodegen # &> /dev/null

xcode:
  @open rewrite/Xcode/Gertrude.xcodeproj

# api

watch-api:
  @just watch-swift . 'just run-api' 'macapp/**/*' 'rewrite/**/*'

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

codegen:
  @cd api && CODEGEN_SWIFT=1 swift test --filter test_codegenSwift

#infra

deploy-prod:
	@node ./api/Infra/deploy.mjs --production

deploy-staging:
	@node ./api/Infra/deploy.mjs

deploy-all:
	@just deploy-staging
	@just deploy-prod

db-sync:
	@node ./api/Infra/db-sync.mjs

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
	@rm -rf pairql-typescript/.build
	@rm -rf shared/.build
	@rm -rf x-kit/.build

clean-api-tests:
	@cd api && find .build -name '*AppTests*' -delete

# helpers

set dotenv-load

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
