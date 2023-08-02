// swift-tools-version:5.7
import PackageDescription

let package = Package(
  name: "XExpect",
  platforms: [.macOS(.v10_15)],
  products: [
    .library(name: "XExpect", targets: ["XExpect"]),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.0.0"),
  ],
  targets: [
    .target(
      name: "XExpect",
      dependencies: [
        .product(name: "CustomDump", package: "swift-custom-dump"),
      ]
    ),
  ]
)
