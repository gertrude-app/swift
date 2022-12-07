// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "GqlMacOS",
  platforms: [.macOS(.v11)],
  products: [
    .library(name: "GqlMacOS", targets: ["GqlMacOS"]),
  ],
  dependencies: [
    .package("pointfreeco/swift-url-routing@0.4.0"),
    .package(path: "../gertieql"),
    .package(path: "../shared"),
  ],
  targets: [
    .target(name: "GqlMacOS", dependencies: [
      .product(name: "URLRouting", package: "swift-url-routing"),
      .product(name: "GertieQL", package: "gertieql"),
      .product(name: "Shared", package: "shared"),
    ]),
    .testTarget(name: "GqlMacOSTests", dependencies: [
      .target(name: "GqlMacOS"),
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
