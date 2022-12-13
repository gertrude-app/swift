// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "DashboardRoute",
  platforms: [.macOS(.v11)],
  products: [
    .library(name: "DashboardRoute", targets: ["DashboardRoute"]),
  ],
  dependencies: [
    .package("pointfreeco/swift-url-routing@0.4.0"),
    .package(path: "../pairql"),
    .package(path: "../pairql-typescript"),
    .package(path: "../shared"),
  ],
  targets: [
    .target(name: "DashboardRoute", dependencies: [
      .product(name: "URLRouting", package: "swift-url-routing"),
      .product(name: "PairQL", package: "pairql"),
      .product(name: "TypescriptPairQL", package: "pairql-typescript"),
      .product(name: "Shared", package: "shared"),
    ]),
    .testTarget(name: "DashboardRouteTests", dependencies: [
      .target(name: "DashboardRoute"),
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
