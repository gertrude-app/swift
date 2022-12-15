// swift-tools-version:5.5
import PackageDescription

let package = Package(
  name: "VaporUtils",
  platforms: [.macOS(.v11)],
  products: [
    .library(name: "XExpect", targets: ["XExpect"]),
  ],
  dependencies: [],
  targets: [
    .target(
      name: "XExpect",
      dependencies: []
    ),
  ]
)
