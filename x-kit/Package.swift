// swift-tools-version:5.7
import PackageDescription

let package = Package(
  name: "XKit",
  platforms: [.macOS(.v11)],
  products: [
    .library(name: "XCore", targets: ["XCore"]),
    .library(name: "XBase64", targets: ["XBase64"]),
  ],
  dependencies: [],
  targets: [
    .target(name: "XCore", dependencies: []),
    .target(name: "XBase64", dependencies: []),
    .testTarget(name: "XCoreTests", dependencies: ["XCore"]),
  ]
)
