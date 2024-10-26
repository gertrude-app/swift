// swift-tools-version: 5.10
import PackageDescription

let package = Package(
  name: "LibIOS",
  platforms: [.macOS(.v14), .iOS(.v17)],
  products: [
    .library(name: "LibCore", targets: ["LibCore"]),
    .library(name: "LibIOS", targets: ["LibIOS"]),
    .library(name: "LibFilter", targets: ["LibFilter"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/pointfreeco/swift-composable-architecture",
      from: "1.0.0"
    ),
    .package(
      url: "https://github.com/pointfreeco/swift-concurrency-extras",
      from: "1.0.0"
    ),
    .package(path: "../../pairql-iosapp"),
    .package(path: "../../gertie"),
    .package(path: "../../x-expect"),
  ],
  targets: [
    .target(
      name: "LibCore",
      dependencies: []
    ),
    .target(
      name: "LibIOS",
      dependencies: [
        "LibCore",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        .product(name: "IOSRoute", package: "pairql-iosapp"),
      ]
    ),
    .target(
      name: "LibFilter",
      dependencies: [
        "LibCore",
        .product(name: "GertieIOS", package: "gertie"),
      ]
    ),
    .testTarget(
      name: "LibIOSTests",
      dependencies: [
        "LibIOS",
        .product(name: "XExpect", package: "x-expect"),
      ]
    ),
    .testTarget(
      name: "LibFilterTests",
      dependencies: [
        "LibFilter",
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
        .product(name: "GertieIOS", package: "gertie"),
        .product(name: "XExpect", package: "x-expect"),
      ]
    ),
  ]
)
