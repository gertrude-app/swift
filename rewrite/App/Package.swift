// swift-tools-version: 5.7
import PackageDescription

let package = Package(
  name: "App",
  platforms: [.macOS(.v10_15)],
  products: [
    .library(name: "App", targets: ["App"]),
    .library(name: "Models", targets: ["Models"]),
    .library(name: "LiveApiClient", targets: ["LiveApiClient"]),
    .library(name: "LiveFilterClient", targets: ["LiveFilterClient"]),
  ],
  dependencies: [
    .github("pointfreeco/swift-composable-architecture", branch: "prerelease/1.0"),
    .github("pointfreeco/swift-dependencies", from: "0.1.0"),
    .github("jaredh159/swift-tagged", from: "0.8.2"),
    .package(path: "../../x-kit"),
    .package(path: "../../pairql-macapp"),
  ],
  targets: [
    .checkedTarget(
      name: "App",
      dependencies: [.tca, "x-kit" => "XCore", "Models"]
    ),
    .checkedTarget(
      name: "Models",
      dependencies: [
        .dependencies,
        "swift-tagged" => "Tagged",
        "pairql-macapp" => "MacAppRoute",
      ]
    ),
    .checkedTarget(
      name: "LiveApiClient",
      dependencies: [.dependencies, "x-kit" => "XCore", "Models"]
    ),
    .checkedTarget(
      name: "LiveFilterClient",
      dependencies: [.dependencies, "Models"]
    ),
    .testTarget(
      name: "AppTests",
      dependencies: ["App", "Models"]
    ),
  ]
)

// extensions, helpers

infix operator =>
private func => (lhs: String, rhs: String) -> Target.Dependency {
  .product(name: rhs, package: lhs)
}

extension Target {
  static func checkedTarget(
    name: String,
    dependencies: [Target.Dependency]
  ) -> Target {
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

extension PackageDescription.Package.Dependency {
  static func github(_ repo: String, from: String) -> Package.Dependency {
    .package(
      url: "https://github.com/\(repo).git",
      from: .init(stringLiteral: "\(from)")
    )
  }

  static func github(_ repo: String, branch: String) -> Package.Dependency {
    .package(
      url: "https://github.com/\(repo).git",
      branch: .init(stringLiteral: "\(branch)")
    )
  }
}

extension Target.Dependency {
  static let tca: Self = .product(
    name: "ComposableArchitecture",
    package: "swift-composable-architecture"
  )
  static let dependencies: Self = .product(
    name: "Dependencies",
    package: "swift-dependencies"
  )
}
