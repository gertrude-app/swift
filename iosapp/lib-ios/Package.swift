// swift-tools-version: 5.10
import PackageDescription

let package = Package(
  name: "LibIOS",
  platforms: [.macOS(.v14), .iOS(.v17)],
  products: [
    .library(name: "LibCore", targets: ["LibCore"]),
    .library(name: "LibFilter", targets: ["LibFilter"]),
    .library(name: "LibController", targets: ["LibController"]),
    .library(name: "LibClients", targets: ["LibClients"]),
  ],
  dependencies: [
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
      name: "LibFilter",
      dependencies: [
        "LibCore",
        "LibClients",
        .product(name: "GertieIOS", package: "gertie"),
        .product(name: "Dependencies", package: "swift-dependencies"),
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
