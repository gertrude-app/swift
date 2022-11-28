api:
	watchexec --restart --clear \
	  --watch api/Sources \
	  --watch api/Package.swift \
	  --exts swift \
	  'cd api && swift build && .build/debug/Run serve --port 8082'

exclude:
	find . -path '**/.build/**/swift-nio*/**/hash.txt' -delete
	find . -path '**/.build/**/swift-nio*/**/*_nasm.inc' -delete
	find . -path '**/.build/**/swift-nio*/**/*_sha1.sh' -delete
	find . -path '**/.build/**/swift-nio*/**/*_llhttp.sh' -delete
	find . -path '**/.build/**/swift-nio*/**/LICENSE-MIT' -delete

# helpers

ALL_CMDS = api

.PHONY: $(ALL_CMDS)
