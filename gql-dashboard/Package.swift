// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "GqlDashboard",
  platforms: [.macOS(.v11)],
  products: [
    .library(name: "GqlDashboard", targets: ["GqlDashboard"]),
  ],
  dependencies: [
    .package("pointfreeco/swift-url-routing@0.4.0"),
    .package(path: "../gertieql"),
    .package(path: "../shared"),
  ],
  targets: [
    .target(name: "GqlDashboard", dependencies: [
      .product(name: "URLRouting", package: "swift-url-routing"),
      .product(name: "GertieQL", package: "gertieql"),
      .product(name: "Shared", package: "shared"),
    ]),
    .testTarget(name: "GqlDashboardTests", dependencies: [
      .target(name: "GqlDashboard"),
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
