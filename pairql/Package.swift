// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "PairQL",
  platforms: [.macOS(.v10_15), .iOS(.v17)],
  products: [
    .library(name: "PairQL", targets: ["PairQL"]),
  ],
  dependencies: [
    // fork avoids swift-syntax transitive dep via case-paths
    .package(url: "https://github.com/gertrude-app/swift-url-routing", revision: "1cf1ca6"),
  ],
  targets: [
    .target(
      name: "PairQL",
      dependencies: [.product(name: "URLRouting", package: "swift-url-routing")],
      swiftSettings: [.unsafeFlags(["-Xfrontend", "-warnings-as-errors"])],
    ),
  ],
)
