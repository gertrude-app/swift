// swift-tools-version:5.7
import PackageDescription

let package = Package(
  name: "SharedCore",
  platforms: [.macOS(.v11)],
  products: [
    .library(name: "SharedCore", targets: ["SharedCore"]),
  ],
  dependencies: [
    .package(name: "Gertie", path: "../../../gertie"),
    .package(name: "XKit", path: "../../../x-kit"),
  ],
  targets: [
    .target(name: "SharedCore", dependencies: [
      .product(name: "Gertie", package: "Gertie"),
      .product(name: "XCore", package: "XKit"),
    ]),
    .testTarget(name: "SharedCoreTests", dependencies: ["SharedCore"]),
  ]
)
