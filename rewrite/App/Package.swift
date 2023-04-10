// swift-tools-version: 5.7
import PackageDescription

let package = Package(
  name: "App",
  platforms: [.macOS(.v10_15)],
  products: [
    .library(name: "App", targets: ["App"]),
    .library(name: "Models", targets: ["Models"]),
    .library(name: "Filter", targets: ["Filter"]),
    .library(name: "Core", targets: ["Core"]),
    .library(name: "LiveApiClient", targets: ["LiveApiClient"]),
    .library(name: "LiveFilterXPCClient", targets: ["LiveFilterXPCClient"]),
    .library(name: "LiveFilterExtensionClient", targets: ["LiveFilterExtensionClient"]),
  ],
  dependencies: [
    .github("pointfreeco/swift-composable-architecture", branch: "prerelease/1.0"),
    .github("pointfreeco/swift-dependencies", from: "0.2.0"),
    .github("jaredh159/swift-tagged", from: "0.8.2"),
    .package(path: "../../x-kit"),
    .package(path: "../../pairql-macapp"),
    .package(path: "../../x-expect"),
    .package(path: "../../shared"),
    .package(path: "../../typescript"),
  ],
  targets: [
    .checkedTarget(
      name: "App",
      dependencies: [.tca, "x-kit" => "XCore", "Core", "Models"]
    ),
    .checkedTarget(
      name: "Models",
      dependencies: [
        .dependencies,
        "Core",
        "swift-tagged" => "Tagged",
        "pairql-macapp" => "MacAppRoute",
        "shared" => "Shared",
      ]
    ),
    .checkedTarget(
      name: "LiveApiClient",
      dependencies: [.dependencies, "x-kit" => "XCore", "Models"]
    ),
    .checkedTarget(
      name: "LiveFilterXPCClient",
      dependencies: [.dependencies, "Core", "Models", "shared" => "Shared"]
    ),
    .checkedTarget(
      name: "LiveFilterExtensionClient",
      dependencies: [.dependencies, "Core", "Models"]
    ),
    .checkedTarget(
      name: "Filter",
      dependencies: [.tca, "Core", "shared" => "Shared"]
    ),
    .checkedTarget(
      name: "Core",
      dependencies: [.dependencies, "shared" => "Shared"]
    ),
    .testTarget(
      name: "AppTests",
      dependencies: ["App", "Models", "x-expect" => "XExpect"]
    ),
    .testTarget(
      name: "Codegen",
      dependencies: ["App", "typescript" => "TypeScript"]
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
