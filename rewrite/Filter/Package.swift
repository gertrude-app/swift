// swift-tools-version: 5.7
import PackageDescription

let package = Package(
  name: "Filter",
  products: [.library(name: "Filter", targets: ["Filter"])],
  dependencies: [],
  targets: [
    .target(name: "Filter", dependencies: []),
    .testTarget(name: "FilterTests", dependencies: ["Filter"]),
  ]
)
