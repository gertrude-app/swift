// swift-tools-version: 5.7
import PackageDescription

let package = Package(
  name: "App",
  platforms: [.macOS(.v10_15)],
  products: [
    .library(name: "App", targets: ["App"]),
    .library(name: "MenuBar", targets: ["MenuBar"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/pointfreeco/swift-composable-architecture",
      branch: "prerelease/1.0"
    ),
    .package(path: "../../shared"),
    .package(path: "../../typescript"),
  ],
  targets: [
    .checkedTarget(
      name: "App",
      dependencies: [.tca, "MenuBar"]
    ),
    .checkedTarget(
      name: "MenuBar",
      dependencies: [.tca, .typescript, .product(name: "Shared", package: "shared")]
    ),
    .testTarget(
      name: "AppTests",
      dependencies: ["App"]
    ),
    .testTarget(
      name: "MenuBarTests",
      dependencies: ["App", .typescript]
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
  static let tca: Target.Dependency = .product(
    name: "ComposableArchitecture",
    package: "swift-composable-architecture"
  )
  static let typescript: Target.Dependency = .product(
    name: "TypeScript",
    package: "typescript"
  )
}
