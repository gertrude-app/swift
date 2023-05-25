// swift-tools-version:5.7
import PackageDescription

let package = Package(
  name: "FilterCore",
  platforms: [.macOS(.v11)],
  products: [
    .library(name: "FilterCore", targets: ["FilterCore"]),
  ],
  dependencies: [
    .package(name: "Gertie", path: "../../../gertie"),
    .package(name: "SharedCore", path: "../SharedCore"),
    .package(url: "https://github.com/pointfreeco/combine-schedulers", from: "0.5.3"),
  ],
  targets: [
    .target(
      name: "FilterCore",
      dependencies: [
        "Gertie",
        "SharedCore",
        .product(name: "CombineSchedulers", package: "combine-schedulers"),
      ]
    ),
    .testTarget(
      name: "FilterCoreTests",
      dependencies: [
        "FilterCore",
        .product(name: "CombineSchedulers", package: "combine-schedulers"),
      ]
    ),
  ]
)
