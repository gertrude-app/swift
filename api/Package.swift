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
    .package("jaredh159/swift-tagged@0.8.2"),
    .package("pointfreeco/vapor-routing@0.1.2"),
    .package("soto-project/soto@5.12.0"),
    .package("m-barthelemy/vapor-queues-fluent-driver@3.0.0-beta", "QueuesFluentDriver"),
    .package(path: "../duet"),
    .package(path: "../shared"),
    .package(path: "../pairql"),
    .package(path: "../pairql-typescript"),
    .package(path: "../pairql-macapp"),
    .package(path: "../x-sendgrid"),
    .package(path: "../x-slack"),
    .package(path: "../x-stripe"),
    .package(path: "../x-expect"),
  ],
  targets: [
    .target(
      name: "Api",
      dependencies: [
        .product(name: "Vapor", package: "vapor"),
        .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
        .product(name: "Fluent", package: "fluent"),
        .product(name: "Duet", package: "duet"),
        .product(name: "DuetSQL", package: "duet"),
        .product(name: "SotoS3", package: "soto"),
        .product(name: "Shared", package: "shared"),
        .product(name: "PairQL", package: "pairql"),
        .product(name: "MacAppRoute", package: "pairql-macapp"),
        .product(name: "TypescriptPairQL", package: "pairql-typescript"),
        .product(name: "TaggedTime", package: "swift-tagged"),
        .product(name: "VaporRouting", package: "vapor-routing"),
        .product(name: "XSendGrid", package: "x-sendgrid"),
        .product(name: "XSlack", package: "x-slack"),
        .product(name: "XStripe", package: "x-stripe"),
        "Rainbow",
        "QueuesFluentDriver",
      ],
      swiftSettings: [
        .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release)),
      ]
    ),
    .executableTarget(name: "Run", dependencies: [.target(name: "Api")]),
    .testTarget(name: "ApiTests", dependencies: [
      .target(name: "Api"),
      .product(name: "XExpect", package: "x-expect"),
      .product(name: "XCTVapor", package: "vapor"), // do i need this?
      .product(name: "DuetMock", package: "duet"),
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
