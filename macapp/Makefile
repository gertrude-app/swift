test: clean
	cd ./Gertrude/AppCore && swift test && \
	cd ../SharedCore && swift test && \
	cd ../FilterCore && swift test && \
	cd ../Websocket && swift test

build: clean
	cd ./Gertrude/AppCore && swift build && \
	cd ../SharedCore && swift build && \
	cd ../FilterCore && swift build && \
	cd ../Websocket && swift build

pkg-appcore-start: clean
	cd ./Gertrude/AppCore && $(WATCHEXEC_SWIFT) swift build

pkg-filtercore-start: clean
	cd ./Gertrude/FilterCore && $(WATCHEXEC_SWIFT) swift build

pkg-sharedcore-start: clean
	cd ./Gertrude/SharedCore && $(WATCHEXEC_SWIFT) swift build

pkg-ws-test:
	cd ./Gertrude/Websocket && swift test

pkg-ws-test-watch:
	cd ./Gertrude/Websocket && $(WATCHEXEC_SWIFT) swift test

start:
	$(CONCURRENTLY) \
	  -n app,fil,sha \
		-c cyan.dim,magenta.dim,yellow.dim \
		"make pkg-appcore-start" "make pkg-filtercore-start" "make pkg-sharedcore-start"

clean:
	rm -f $(FILTER_CORE)/$(CHECKOUTS)/swift-nio/Sources/CNIOHTTPParser/update_and_patch_http_parser.sh
	rm -f $(FILTER_CORE)/$(CHECKOUTS)/swift-nio/Sources/CNIOHTTPParser/AUTHORS
	rm -f $(FILTER_CORE)/$(CHECKOUTS)/swift-nio/Sources/CNIOHTTPParser/LICENSE-MIT
	rm -f $(FILTER_CORE)/$(CHECKOUTS)/swift-nio/Sources/CNIOSHA1/update_and_patch_sha1.sh
	rm -f $(FILTER_CORE)/$(CHECKOUTS)/swift-nio-ssl/Sources/CNIOBoringSSL/hash.txt
	rm -f $(FILTER_CORE)/$(CHECKOUTS)/swift-nio-ssl/Sources/CNIOBoringSSL/include/boringssl_prefix_symbols_nasm.inc
	rm -f $(SHARED_CORE)/$(CHECKOUTS)/swift-nio/Sources/CNIOHTTPParser/update_and_patch_http_parser.sh
	rm -f $(SHARED_CORE)/$(CHECKOUTS)/swift-nio/Sources/CNIOHTTPParser/AUTHORS
	rm -f $(SHARED_CORE)/$(CHECKOUTS)/swift-nio/Sources/CNIOHTTPParser/LICENSE-MIT
	rm -f $(SHARED_CORE)/$(CHECKOUTS)/swift-nio/Sources/CNIOSHA1/update_and_patch_sha1.sh
	rm -f $(SHARED_CORE)/$(CHECKOUTS)/swift-nio-ssl/Sources/CNIOBoringSSL/hash.txt
	rm -f $(SHARED_CORE)/$(CHECKOUTS)/swift-nio-ssl/Sources/CNIOBoringSSL/include/boringssl_prefix_symbols_nasm.inc
	rm -f $(APP_CORE)/$(CHECKOUTS)/swift-nio/Sources/CNIOHTTPParser/update_and_patch_http_parser.sh
	rm -f $(APP_CORE)/$(CHECKOUTS)/swift-nio/Sources/CNIOHTTPParser/AUTHORS
	rm -f $(APP_CORE)/$(CHECKOUTS)/swift-nio/Sources/CNIOHTTPParser/LICENSE-MIT
	rm -f $(APP_CORE)/$(CHECKOUTS)/swift-nio/Sources/CNIOSHA1/update_and_patch_sha1.sh
	rm -f $(APP_CORE)/$(CHECKOUTS)/swift-nio-ssl/Sources/CNIOBoringSSL/hash.txt
	rm -f $(APP_CORE)/$(CHECKOUTS)/swift-nio-ssl/Sources/CNIOBoringSSL/include/boringssl_prefix_symbols_nasm.inc
	rm -f $(WEBSOCKET)/$(CHECKOUTS)/swift-nio/Sources/CNIOHTTPParser/update_and_patch_http_parser.sh
	rm -f $(WEBSOCKET)/$(CHECKOUTS)/swift-nio/Sources/CNIOHTTPParser/AUTHORS
	rm -f $(WEBSOCKET)/$(CHECKOUTS)/swift-nio/Sources/CNIOHTTPParser/LICENSE-MIT
	rm -f $(WEBSOCKET)/$(CHECKOUTS)/swift-nio/Sources/CNIOSHA1/update_and_patch_sha1.sh
	rm -f $(WEBSOCKET)/$(CHECKOUTS)/swift-nio-ssl/Sources/CNIOBoringSSL/hash.txt
	rm -f $(WEBSOCKET)/$(CHECKOUTS)/swift-nio-ssl/Sources/CNIOBoringSSL/include/boringssl_prefix_symbols_nasm.inc

format:
	swiftformat .

sparkle-zip-release:
	cd ~/gertie/app-updates && \
	ditto -c -k --sequesterRsrc --keepParent Gertrude.app Gertrude.X.Y.Z.zi

ALL_CMDS = \
	test \
	start pkg-appcore-start pkg-sharedcore-start pkg-filtercore-start \
	pkg-ws-test pkg-ws-test-watch \
	build \
	clean \
	sparkle-zip-release sparkle-generate-appcast \
	format

.PHONY: $(ALL_CMDS)
.SILENT: $(ALL_CMDS)

CONCURRENTLY = node_modules/.bin/concurrently
SHARED_CORE = ./Gertrude/SharedCore
APP_CORE = ./Gertrude/AppCore
FILTER_CORE = ./Gertrude/FilterCore
WEBSOCKET = ./Gertrude/Websocket
CHECKOUTS = .build/checkouts
WATCHEXEC_SWIFT = watchexec $(WATCHEXEC_SWIFT_FLAGS)
WATCHEXEC_SWIFT_FLAGS = \
	--restart \
	--clear \
	--watch Sources \
	--watch Tests \
	--watch Package.swift \
	--exts swift
