// swift-tools-version:5.7
import PackageDescription

let package = Package(
  name: "PairQL",
  platforms: [.macOS(.v10_15)],
  products: [
    .library(name: "PairQL", targets: ["PairQL"]),
  ],
  dependencies: [
    // fork avoids swift-syntax transitive dep via case-paths
    .package(url: "https://github.com/gertrude-app/swift-url-routing", revision: "1cf1ca6"),
    .package(path: "../x-expect"),
  ],
  targets: [
    .target(
      name: "PairQL",
      dependencies: [.product(name: "URLRouting", package: "swift-url-routing")],
      swiftSettings: [.unsafeFlags([
        "-Xfrontend", "-warn-concurrency",
        "-Xfrontend", "-enable-actor-data-race-checks",
        "-Xfrontend", "-warnings-as-errors",
      ])]
    ),
    .testTarget(name: "PairQLTests", dependencies: [
      .target(name: "PairQL"),
      .product(name: "XExpect", package: "x-expect"),
    ]),
  ]
)
