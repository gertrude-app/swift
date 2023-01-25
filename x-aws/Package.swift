// swift-tools-version:5.5

import PackageDescription

let package = Package(
  name: "XAws",
  platforms: [.macOS(.v12)],
  products: [
    .library(name: "XAws", targets: ["XAws"]),
  ],
  dependencies: [
    .package("apple/swift-crypto@2.2.4"),
    .package(path: "../x-expect"),
  ],
  targets: [
    .target(name: "XAws", dependencies: [
      .product(name: "Crypto", package: "swift-crypto"),
    ]),
    .testTarget(
      name: "XAwsTests",
      dependencies: ["XAws", .product(name: "XExpect", package: "x-expect")]
    ),
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
