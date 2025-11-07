// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "LibIOS",
  platforms: [.macOS(.v14), .iOS(.v17)],
  products: [
    .library(name: "LibCore", targets: ["LibCore"]),
    .library(name: "LibFilter", targets: ["LibFilter"]),
    .library(name: "LibController", targets: ["LibController"]),
    .library(name: "LibClients", targets: ["LibClients"]),
    .library(name: "LibApp", targets: ["LibApp"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/pointfreeco/swift-dependencies",
      from: "1.8.1",
    ),
    .package(
      url: "https://github.com/pointfreeco/swift-concurrency-extras",
      from: "1.3.1",
    ),
    .package(
      url: "https://github.com/pointfreeco/swift-composable-architecture",
      from: "1.18.0",
    ),
    .package(path: "../../pairql-iosapp"),
    .package(path: "../../gertie"),
    .package(path: "../../x-expect"),
    .package(path: "../../x-kit"),
  ],
  targets: [
    .target(
      name: "LibCore",
      dependencies: [
        .product(name: "GertieIOS", package: "gertie"),
      ],
    ),
    .target(
      name: "LibFilter",
      dependencies: [
        "LibCore",
        "LibClients",
        .product(name: "XCore", package: "x-kit"),
        .product(name: "GertieIOS", package: "gertie"),
        .product(name: "Dependencies", package: "swift-dependencies"),
      ],
    ),
    .target(
      name: "LibApp",
      dependencies: [
        "LibCore",
        "LibClients",
        .product(name: "GertieIOS", package: "gertie"),
        .product(name: "XCore", package: "x-kit"),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ],
    ),
    .target(
      name: "LibController",
      dependencies: [
        "LibClients",
      ],
    ),
    .target(
      name: "LibClients",
      dependencies: [
        "LibCore",
        .product(name: "GertieIOS", package: "gertie"),
        .product(name: "IOSRoute", package: "pairql-iosapp"),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "DependenciesMacros", package: "swift-dependencies"),
      ],
    ),
    .testTarget(
      name: "LibFilterTests",
      dependencies: [
        "LibFilter",
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
        .product(name: "GertieIOS", package: "gertie"),
        .product(name: "XExpect", package: "x-expect"),
      ],
    ),
    .testTarget(
      name: "LibAppTests",
      dependencies: [
        "LibApp",
        .product(name: "XExpect", package: "x-expect"),
      ],
    ),
    .testTarget(
      name: "LibControllerTests",
      dependencies: [
        "LibController",
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
        .product(name: "GertieIOS", package: "gertie"),
        .product(name: "XExpect", package: "x-expect"),
      ],
    ),
  ],
)
