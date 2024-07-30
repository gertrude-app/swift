// swift-tools-version:5.7
import PackageDescription

let package = Package(
  name: "api",
  platforms: [.macOS(.v12)],
  dependencies: [
    .package("vapor/vapor@4.93.0"),
    .package("vapor/fluent@4.9.0"),
    .package("vapor/fluent-postgres-driver@2.8.0"),
    .package("onevcat/Rainbow@4.0.1"),
    .package("jaredh159/swift-tagged@0.8.2"),
    .package("pointfreeco/vapor-routing@0.1.3"),
    .package("m-barthelemy/vapor-queues-fluent-driver@3.0.0-beta"),
    .package(path: "../duet"),
    .package(path: "../gertie"),
    .package(path: "../pairql"),
    .package(path: "../pairql-macapp"),
    .package(path: "../ts-interop"),
    .package(path: "../x-aws"),
    .package(path: "../x-sendgrid"),
    .package(path: "../x-postmark"),
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
        .product(name: "QueuesFluentDriver", package: "vapor-queues-fluent-driver"),
        .product(name: "Fluent", package: "fluent"),
        .product(name: "Duet", package: "duet"),
        .product(name: "DuetSQL", package: "duet"),
        .product(name: "TypeScriptInterop", package: "ts-interop"),
        .product(name: "Gertie", package: "gertie"),
        .product(name: "PairQL", package: "pairql"),
        .product(name: "MacAppRoute", package: "pairql-macapp"),
        .product(name: "TaggedTime", package: "swift-tagged"),
        .product(name: "VaporRouting", package: "vapor-routing"),
        .product(name: "XAws", package: "x-aws"),
        .product(name: "XSendGrid", package: "x-sendgrid"),
        .product(name: "XPostmark", package: "x-postmark"),
        .product(name: "XSlack", package: "x-slack"),
        .product(name: "XStripe", package: "x-stripe"),
        "Rainbow",
      ],
      swiftSettings: [
        .unsafeFlags([
          "-Xfrontend", "-warn-concurrency",
          "-Xfrontend", "-enable-actor-data-race-checks",
        ]),
        .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release)),
      ]
    ),
    .executableTarget(name: "Run", dependencies: [.target(name: "Api")]),
    .testTarget(name: "ApiTests", dependencies: [
      .target(name: "Api"),
      .product(name: "XExpect", package: "x-expect"),
      .product(name: "XCTVapor", package: "vapor"),
    ]),
  ]
)

import Foundation

if ProcessInfo.processInfo.environment["CI"] != nil {
  package.targets[0].swiftSettings?.append(
    .unsafeFlags(["-Xfrontend", "-warnings-as-errors"])
  )
}

// helpers

extension PackageDescription.Package.Dependency {
  static func package(_ commitish: String) -> Package.Dependency {
    let parts = commitish.split(separator: "@")
    return .package(
      url: "https://github.com/\(parts[0]).git",
      from: .init(stringLiteral: "\(parts[1])")
    )
  }
}
