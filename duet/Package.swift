// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Duet",
  platforms: [.macOS(.v11)],
  products: [
    .library(name: "Duet", targets: ["Duet"]),
    .library(name: "DuetSQL", targets: ["DuetSQL"]),
    .library(name: "DuetMock", targets: ["DuetMock"]),
  ],
  dependencies: [
    .package(path: "../x-kit"),
    .package(path: "../x-expect"),
    .package("vapor/fluent-kit@1.16.0"),
    .package("jaredh159/swift-tagged@0.8.2"),
    .package("wickwirew/Runtime@2.2.4"),
  ],
  targets: [
    .target(
      name: "Duet",
      dependencies: [
        .product(name: "XCore", package: "x-kit"),
        .product(name: "Tagged", package: "swift-tagged"),
      ]
    ),
    .target(
      name: "DuetSQL",
      dependencies: [
        "Duet",
        "Runtime",
        .product(name: "FluentSQL", package: "fluent-kit"),
        .product(name: "XCore", package: "x-kit"),
        .product(name: "Tagged", package: "swift-tagged"),
      ]
    ),
    .target(name: "DuetMock", dependencies: ["Duet"]),
    .testTarget(
      name: "DuetSQLTests",
      dependencies: ["DuetSQL", .product(name: "XExpect", package: "x-expect")]
    ),
    .testTarget(
      name: "DuetTests",
      dependencies: ["Duet", .product(name: "XExpect", package: "x-expect")]
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
