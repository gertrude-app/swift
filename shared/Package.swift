// swift-tools-version:5.7

import PackageDescription

let package = Package(
  name: "Shared",
  platforms: [.macOS(.v11)],
  products: [.library(name: "Shared", targets: ["Shared"])],
  dependencies: [
    .package("jaredh159/swift-tagged@0.8.2"),
    .package(path: "../x-kit"),
    .package(path: "../x-expect"),
  ],
  targets: [
    .target(name: "Shared", dependencies: [
      .product(name: "XCore", package: "x-kit"),
      .product(name: "TaggedTime", package: "swift-tagged"),
    ]),
    .testTarget(
      name: "SharedTests",
      dependencies: [
        "Shared",
        .product(name: "XExpect", package: "x-expect"),
      ]
    ),
  ]
)

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
