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

macapp:
  @open macapp/Xcode/Gertrude.xcodeproj

# ios

watch-ios:
  @just watch-build iosapp/lib-ios

iosapp:
  @open iosapp/Gertrude-iOS.xcodeproj

# api

watch-api:
  @just watch-swift . 'just run-api' 'macapp/**/*'

run-api: build-api
  @just exec-api serve

run-api-ip: build-api
  @just exec-api serve --hostname 192.168.50.106

build-api:
  @cd api && swift build

migrate-up: build-api
  @just exec-api migrate --yes

migrate-down: build-api
  @just exec-api migrate --revert --yes

reset: build-api
  just exec-api reset

sync-staging-data: build-api
  @just exec-api sync-staging-data

nuke-test-db:
  @killall -q Postico; dropdb --if-exists gertrude_test; createdb gertrude_test

# emails (requires local dev api running)

send-email template:
  @curl http://127.0.0.1:8080/send-test-email/{{template}}

sync-email-templates:
  @curl http://127.0.0.1:8080/sync-email-templates

web-email template:
  @curl -s http://127.0.0.1:8080/web-test-email/{{template}}

# NB: requires `concurrently`, `vite` in $PATH
watch-web-email template:
  @concurrently -n serve,regen -c cyan.dim,magenta.dim \
    "vite" \
    "bash -c 'while true; do just web-email {{template}}; sleep 2; done;'" \
    "cd dev-emails && npm run dev"

# infra

db-sync:
  @node ../infra/db-sync.mjs

# root

build:
  @just nx-run-many build

test:
  @just nx-run-many test

lint-swift:
  @swiftformat . --lint

lint-swift-fix:
  @swiftformat .

lint-xml:
  @xml-lint {{xmlfiles}}

lint-xml-fix:
  @xml-lint --fix {{xmlfiles}}

lint:
  @just lint-swift
  @just lint-xml

lint-fix:
  @just lint-swift-fix
  @just lint-xml-fix

check:
  @just build
  @just test
  @just lint

nx-reset:
  @pnpm nx reset

clean: nx-reset
  @rm -rf node_modules/.cache
  @rm -rf api/.build duet/.build gertie/.build
  @rm -rf macapp/App/.build iosapp/lib-ios/.build
  @rm -rf pairql/.build pairql-macapp/.build pairql-iosapp/.build
  @rm -rf ts-interop/.build x-aws/.build x-http/.build
  @rm -rf x-kit/.build x-postmark/.build x-slack/.build x-stripe/.build

# helpers

[private]
exec-api cmd *args:
  @cd api && ./.build/debug/Run {{cmd}} {{args}}

[private]
nx-run-many targets:
  @pnpm exec nx run-many --parallel=10 --targets={{targets}}

[private]
watch-swift dir cmd ignore1="•" ignore2="•":
  @watchexec --project-origin . --clear --restart --watch {{dir}} --exts swift,html \
  --ignore '**/.build/*/**' --ignore '**/index.html' --ignore '{{ignore1}}' --ignore '{{ignore2}}' \
  {{cmd}}

watch-build dir:
  @just watch-swift {{dir}} '"cd {{dir}} && swift build"'

watch-test dir isolate="":
  @just watch-swift {{dir}} '"cd {{dir}} && \
  SWIFT_DETERMINISTIC_HASHING=1 swift test \
  {{ if isolate != "" { "--filter " + isolate } else { "" } }} "'

# variables

xmlfiles := """
./iosapp/app/app.entitlements \
./iosapp/app/Info.plist \
./iosapp/controller/controller.entitlements \
./iosapp/controller/Info.plist \
./iosapp/filter/filter.entitlements \
./iosapp/filter/Info.plist \
./iosapp/recorder/recorder.entitlements \
./iosapp/recorder/Info.plist \
./macapp/Xcode/GertrudeFilterExtension/GertrudeFilterExtension.entitlements \
./macapp/Xcode/GertrudeFilterExtension/Info.plist \
./macapp/Xcode/Gertrude/Gertrude.entitlements \
./macapp/Xcode/Gertrude/Info.plist \
./macapp/Xcode/GertrudeRelauncher/GertrudeRelauncher.entitlements
"""
