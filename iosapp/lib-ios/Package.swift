// swift-tools-version: 5.10

import PackageDescription

let package = Package(
  name: "App",
  platforms: [.macOS(.v13), .iOS(.v17)],
  products: [
    .library(name: "App", targets: ["App"]),
    .library(name: "Filter", targets: ["Filter"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/pointfreeco/swift-composable-architecture",
      from: "1.0.0"
    ),
  ],
  targets: [
    .target(
      name: "App",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "Filter",
      dependencies: []
    ),
    .testTarget(
      name: "AppTests",
      dependencies: ["App"]
    ),
    .testTarget(
      name: "FilterTests",
      dependencies: ["Filter"]
    ),
  ]
)
