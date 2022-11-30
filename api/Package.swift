// swift-tools-version:5.5
import PackageDescription

let package = Package(
  name: "api",
  platforms: [.macOS(.v12)],
  dependencies: [
    .package("vapor/vapor@4.67.4"),
    .package("vapor/fluent@4.5.0"),
    .package("vapor/fluent-postgres-driver@2.4.0"),
    .package("onevcat/Rainbow@4.0.1"),
    .package("pointfreeco/swift-tagged@0.8.0"),
    .package(path: "../duet"),
    .package(path: "../shared"),
  ],
  targets: [
    .target(
      name: "App",
      dependencies: [
        .product(name: "Vapor", package: "vapor"),
        .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
        .product(name: "Fluent", package: "fluent"),
        .product(name: "Duet", package: "duet"),
        .product(name: "DuetSQL", package: "duet"),
        .product(name: "Shared", package: "shared"),
        .product(name: "TaggedTime", package: "swift-tagged"),
        "Rainbow",
      ],
      exclude: ["Database/Migrations/foo.sql"], // temp
      swiftSettings: [
        .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release)),
      ]
    ),
    .executableTarget(name: "Run", dependencies: [.target(name: "App")]),
    .testTarget(name: "AppTests", dependencies: [
      .target(name: "App"),
      .product(name: "XCTVapor", package: "vapor"),
    ]),
  ]
)

// helpers

extension PackageDescription.Package.Dependency {
  static func package(_ commitish: String, _ name: String? = nil) -> Package.Dependency {
    let parts = commitish.split(separator: "@")
    return .package(
      name: name,
      url: "https://github.com/\(parts[0]).git",
      from: .init(stringLiteral: "\(parts[1])")
    )
  }
}
