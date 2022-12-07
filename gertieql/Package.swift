// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "GertieQL",
  platforms: [.macOS(.v11)],
  products: [
    .library(name: "GertieQL", targets: ["GertieQL"]),
  ],
  dependencies: [
    .package(path: "../shared"),
  ],
  targets: [
    .target(name: "GertieQL", dependencies: [
      .product(name: "Shared", package: "shared"),
    ]),
    .testTarget(name: "GertieQLTests", dependencies: []),
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
