api:
	watchexec --restart --clear \
	  --watch api/Sources \
	  --watch api/Package.swift \
	  --exts swift \
	  'api/.build/debug/Run serve --port 8082'

# helpers

ALL_CMDS = api

.PHONY: $(ALL_CMDS)
