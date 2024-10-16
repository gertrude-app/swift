// swift-tools-version: 5.10
import PackageDescription

let package = Package(
  name: "LibIOS",
  platforms: [.macOS(.v14), .iOS(.v17)],
  products: [
    .library(name: "LibIOS", targets: ["LibIOS"]),
    .library(name: "LibFilter", targets: ["LibFilter"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/pointfreeco/swift-composable-architecture",
      from: "1.0.0"
    ),
    .package(path: "../../pairql-iosapp"),
  ],
  targets: [
    .target(
      name: "LibIOS",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        .product(name: "IOSRoute", package: "pairql-iosapp"),
      ]
    ),
    .target(
      name: "LibFilter",
      dependencies: []
    ),
    .testTarget(
      name: "LibIOSTests",
      dependencies: ["LibIOS"]
    ),
    .testTarget(
      name: "LibFilterTests",
      dependencies: ["LibFilter"]
    ),
  ]
)
