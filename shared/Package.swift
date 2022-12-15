// swift-tools-version:5.5

import PackageDescription

let package = Package(
  name: "Shared",
  platforms: [.macOS(.v11)],
  products: [.library(name: "Shared", targets: ["Shared"])],
  dependencies: [
    .package(path: "../x-kit"),
    .package(path: "../x-expect"),
  ],
  targets: [
    .target(name: "Shared", dependencies: [
      .product(name: "XCore", package: "x-kit"),
    ]),
    .testTarget(
      name: "SharedTests",
      dependencies: [
        "Shared",
        .product(name: "XExpect", package: "x-expect"),
      ]
    ),
  ]
)
