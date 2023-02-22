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
  ],
  targets: [
    .target(name: "TypeScript", dependencies: []),
    .testTarget(
      name: "TypeScriptTests",
      dependencies: ["TypeScript", .product(name: "XExpect", package: "x-expect")]
    ),
  ]
)
