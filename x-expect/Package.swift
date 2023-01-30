// swift-tools-version:5.7
import PackageDescription

let package = Package(
  name: "XExpect",
  platforms: [.macOS(.v11)],
  products: [
    .library(name: "XExpect", targets: ["XExpect"]),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "0.3.0"),
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
