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
    .library(name: "LiveUpdaterClient", targets: ["LiveUpdaterClient"]),
    .library(name: "LiveWebSocketClient", targets: ["LiveWebSocketClient"]),
    .library(name: "TestSupport", targets: ["TestSupport"]),
  ],
  dependencies: [
    .github("pointfreeco/swift-composable-architecture", branch: "prerelease/1.0"),
    .github("pointfreeco/swift-dependencies", from: "0.2.0"),
    .github("pointfreeco/combine-schedulers", from: "0.10.0"),
    .github("jaredh159/swift-tagged", from: "0.8.2"),
    .github("daltoniam/Starscream", from: "4.0.4"),
    // @see: https://gist.github.com/jaredh159/5fafcdc04de9234ab4bab52897da7334
    .package(url: "https://github.com/jaredh159/Sparkle", exact: "2.2.556"),
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
      name: "LiveUpdaterClient",
      dependencies: [.dependencies, "App", "Core", "shared" => "Shared", "Sparkle"]
    ),
    .checkedTarget(
      name: "LiveWebSocketClient",
      dependencies: [
        .dependencies,
        "Models",
        "Core",
        "shared" => "Shared",
        "x-kit" => "XCore",
        "Starscream",
        "combine-schedulers" => "CombineSchedulers",
      ]
    ),
    .checkedTarget(
      name: "Filter",
      dependencies: [.tca, "Core", "x-kit" => "XCore", "shared" => "Shared"],
      linkerSettings: [.linkedLibrary("bsm")]
    ),
    .checkedTarget(
      name: "Core",
      dependencies: [.dependencies, "shared" => "Shared"]
    ),
    .target(
      name: "TestSupport",
      dependencies: [.tca, "x-expect" => "XExpect"]
    ),
    .testTarget(
      name: "AppTests",
      dependencies: [
        "App",
        "Models",
        "TestSupport",
        "x-expect" => "XExpect",
        "x-kit" => "XCore",
      ]
    ),
    .testTarget(
      name: "FilterTests",
      dependencies: ["Filter", "Core", "TestSupport", "x-expect" => "XExpect"]
    ),
    .testTarget(
      name: "WebSocketTests",
      dependencies: [
        "LiveWebSocketClient",
        "Core",
        "shared" => "Shared",
        "TestSupport",
        "x-expect" => "XExpect",
        "x-kit" => "XCore",
        "combine-schedulers" => "CombineSchedulers",
        "Starscream",
      ]
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
    dependencies: [Target.Dependency],
    linkerSettings: [LinkerSetting] = []
  ) -> Target {
    .target(
      name: name,
      dependencies: dependencies,
      swiftSettings: [
        .unsafeFlags([
          "-Xfrontend", "-warn-concurrency",
          "-Xfrontend", "-enable-actor-data-race-checks",
        ]),
      ],
      linkerSettings: linkerSettings
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
