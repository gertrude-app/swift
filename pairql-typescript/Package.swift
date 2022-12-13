// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "TypescriptPairQL",
  platforms: [.macOS(.v11)],
  products: [
    .library(name: "TypescriptPairQL", targets: ["TypescriptPairQL"]),
  ],
  dependencies: [
    .package("wickwirew/Runtime@2.2.4"),
    .package(path: "../pairql"),
  ],
  targets: [
    .target(name: "TypescriptPairQL", dependencies: [
      .product(name: "Runtime", package: "Runtime"),
      .product(name: "PairQL", package: "pairql"),
    ]),
    .testTarget(name: "TypescriptPairQLTests", dependencies: [
      .target(name: "TypescriptPairQL"),
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
