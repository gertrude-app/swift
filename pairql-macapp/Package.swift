// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "MacAppRoute",
  platforms: [.macOS(.v11)],
  products: [
    .library(name: "MacAppRoute", targets: ["MacAppRoute"]),
  ],
  dependencies: [
    .package("pointfreeco/swift-url-routing@0.4.0"),
    .package(path: "../pairql"),
    .package(path: "../shared"),
    .package(path: "../x-expect"),
  ],
  targets: [
    .target(name: "MacAppRoute", dependencies: [
      .product(name: "URLRouting", package: "swift-url-routing"),
      .product(name: "PairQL", package: "pairql"),
      .product(name: "Shared", package: "shared"),
    ]),
    .testTarget(name: "MacAppRouteTests", dependencies: [
      .target(name: "MacAppRoute"),
      .product(name: "XExpect", package: "x-expect"),
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
