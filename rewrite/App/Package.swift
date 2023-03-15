// swift-tools-version: 5.7
import PackageDescription

let package = Package(
  name: "App",
  platforms: [.macOS(.v10_15)],
  products: [
    .library(name: "App", targets: ["App"]),
    .library(name: "Models", targets: ["Models"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/pointfreeco/swift-composable-architecture",
      branch: "prerelease/1.0"
    ),
    .package(path: "../../x-kit"),
  ],
  targets: [
    .checkedTarget(
      name: "App",
      dependencies: [.tca, .product(name: "XCore", package: "x-kit"), "Models"]
    ),
    .checkedTarget(
      name: "Models",
      dependencies: []
    ),
    .testTarget(
      name: "AppTests",
      dependencies: ["App", "Models"]
    ),
  ]
)

extension Target {
  static func checkedTarget(name: String, dependencies: [Target.Dependency]) -> Target {
    .target(
      name: name,
      dependencies: dependencies,
      swiftSettings: [
        .unsafeFlags([
          "-Xfrontend", "-warn-concurrency",
          "-Xfrontend", "-enable-actor-data-race-checks",
        ]),
      ]
    )
  }
}

extension Target.Dependency {
  static let tca: Self = .product(
    name: "ComposableArchitecture",
    package: "swift-composable-architecture"
  )
}
