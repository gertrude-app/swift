// swift-tools-version:5.7
import PackageDescription

let package = Package(
  name: "TypeScript",
  platforms: [.macOS(.v10_15)],
  products: [
    .library(name: "TypeScript", targets: ["TypeScript"]),
  ],
  dependencies: [
    .package(path: "../x-expect"),
    .package(url: "https://github.com/wickwirew/Runtime.git", from: "2.2.4"),
  ],
  targets: [
    .target(name: "TypeScript", dependencies: [
      .product(name: "Runtime", package: "Runtime"),
    ]),
    .testTarget(
      name: "TypeScriptTests",
      dependencies: ["TypeScript", .product(name: "XExpect", package: "x-expect")]
    ),
  ]
)
