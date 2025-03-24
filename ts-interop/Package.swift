// swift-tools-version: 6.0
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
      swiftSettings: [.unsafeFlags(["-Xfrontend", "-warnings-as-errors"])]
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
