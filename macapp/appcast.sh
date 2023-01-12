DERIVED_DIR=$(xcodebuild -project ./Gertrude.xcodeproj -showBuildSettings 2> /dev/null | grep -m 1 BUILT_PRODUCTS_DIR | sed -e 's/    BUILT_PRODUCTS_DIR = //' | sed -e 's/\/Build\/Products\/Release//')
${DERIVED_DIR}/SourcePackages/artifacts/Sparkle/bin/generate_appcast /Users/jared/gertie/app-updates/
echo "upload appcast.xml and most recent build to cloud location"
