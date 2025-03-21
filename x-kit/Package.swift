// swift-tools-version: 6.0
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
      swiftSettings: [.unsafeFlags(["-Xfrontend", "-warnings-as-errors"])]
    ),
    .target(
      name: "XBase64",
      swiftSettings: [.unsafeFlags(["-Xfrontend", "-warnings-as-errors"])]
    ),
    .testTarget(name: "XCoreTests", dependencies: ["XCore"]),
  ]
)
