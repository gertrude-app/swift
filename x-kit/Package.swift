// swift-tools-version:5.10
import PackageDescription

let package = Package(
  name: "XKit",
  platforms: [.macOS(.v10_15), .iOS(.v17)],
  products: [
    .library(name: "XCore", targets: ["XCore"]),
    .library(name: "XBase64", targets: ["XBase64"]),
  ],
  dependencies: [],
  targets: [
    .target(
      name: "XCore",
      dependencies: [],
      swiftSettings: [.unsafeFlags([
        "-Xfrontend", "-warn-concurrency",
        "-Xfrontend", "-enable-actor-data-race-checks",
        "-Xfrontend", "-warnings-as-errors",
      ])]
    ),
    .target(
      name: "XBase64",
      dependencies: [],
      swiftSettings: [.unsafeFlags([
        "-Xfrontend", "-warn-concurrency",
        "-Xfrontend", "-enable-actor-data-race-checks",
        "-Xfrontend", "-warnings-as-errors",
      ])]
    ),
    .testTarget(name: "XCoreTests", dependencies: ["XCore"]),
  ]
)
