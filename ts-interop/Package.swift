// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "TypeScriptInterop",
  products: [
    .library(name: "TypeScriptInterop", targets: ["TypeScriptInterop"]),
  ],
  dependencies: [
    .package(url: "https://github.com/wickwirew/Runtime.git", from: "2.2.7"),
    .package(path: "../x-expect"),
  ],
  targets: [
    .executableTarget(
      name: "TypeScriptInteropCLI",
      dependencies: []
    ),
    .target(
      name: "TypeScriptInterop",
      dependencies: [
        .product(name: "Runtime", package: "Runtime"),
      ],
      swiftSettings: [
        .unsafeFlags([
          "-Xfrontend", "-warn-concurrency",
          "-Xfrontend", "-enable-actor-data-race-checks",
          "-Xfrontend", "-warnings-as-errors",
        ]),
      ]
    ),
    .testTarget(
      name: "TypeScriptInteropTests",
      dependencies: [
        "TypeScriptInteropCLI",
        "TypeScriptInterop",
        .product(name: "XExpect", package: "x-expect"),
      ]
    ),
  ]
)
