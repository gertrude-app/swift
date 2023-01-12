// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SharedCore",
  platforms: [.macOS(.v11)],
  products: [
    .library(name: "SharedCore", targets: ["SharedCore"]),
  ],
  dependencies: [
    .package(name: "Shared", path: "../../../shared"),
    .package(name: "XKit", path: "../../../x-kit"),
  ],
  targets: [
    .target(name: "SharedCore", dependencies: [
      .product(name: "Shared", package: "Shared"),
      .product(name: "XCore", package: "XKit"),
    ]),
    .testTarget(name: "SharedCoreTests", dependencies: ["SharedCore"]),
  ]
)
