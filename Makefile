api:
	watchexec --restart --clear \
	  --watch api/Sources \
	  --watch api/Package.swift \
	  --exts swift \
	  'make build-api && make run-api'

build-api:
	cd api && swift build

run-api:
	$(API_RUN) serve --port 8082

migrate-up: build-api
	$(API_RUN) migrate --yes

migrate-down: build-api
	$(API_RUN) migrate --revert --yes

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

# helpers

ALL_CMDS = api build-api run-api migrate-up migrate-down exclude clean
API_RUN = cd api && ./.build/debug/Run

.PHONY: $(ALL_CMDS)
.SILENT: $(ALL_CMDS)
