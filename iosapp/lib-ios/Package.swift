// swift-tools-version: 5.10
import PackageDescription

let package = Package(
  name: "LibIOS",
  platforms: [.macOS(.v14), .iOS(.v17)],
  products: [
    .library(name: "LibIOS", targets: ["LibIOS"]),
    .library(name: "LibCore", targets: ["LibCore"]),
    .library(name: "LibFilter", targets: ["LibFilter"]),
    .library(name: "LibController", targets: ["LibController"]),
    .library(name: "LibClients", targets: ["LibClients"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/pointfreeco/swift-composable-architecture",
      from: "1.0.0"
    ),
    .package(
      url: "https://github.com/pointfreeco/swift-dependencies",
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
        "LibClients",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "LibFilter",
      dependencies: [
        "LibCore",
        .product(name: "GertieIOS", package: "gertie"),
      ]
    ),
    .target(
      name: "LibController",
      dependencies: [
        "LibClients",
      ]
    ),
    .target(
      name: "LibClients",
      dependencies: [
        "LibCore",
        .product(name: "GertieIOS", package: "gertie"),
        .product(name: "IOSRoute", package: "pairql-iosapp"),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "DependenciesMacros", package: "swift-dependencies"),
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
    .testTarget(
      name: "LibControllerTests",
      dependencies: [
        "LibController",
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
        .product(name: "GertieIOS", package: "gertie"),
        .product(name: "XExpect", package: "x-expect"),
      ]
    ),
  ]
)
