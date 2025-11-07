// swift-tools-version:6.0
import PackageDescription

let package = Package(
  name: "Duet",
  platforms: [.macOS(.v13)],
  products: [
    .library(name: "Duet", targets: ["Duet"]),
    .library(name: "DuetSQL", targets: ["DuetSQL"]),
  ],
  dependencies: [
    .package(path: "../x-kit"),
    .package(path: "../x-expect"),
    .package("vapor/fluent-postgres-driver@2.9.2"),
    .package("jaredh159/swift-tagged@0.8.2"),
  ],
  targets: [
    .target(
      name: "Duet",
      dependencies: [
        .product(name: "XCore", package: "x-kit"),
        .product(name: "Tagged", package: "swift-tagged"),
      ],
      swiftSettings: [.unsafeFlags(["-Xfrontend", "-warnings-as-errors"])],
    ),
    .target(
      name: "DuetSQL",
      dependencies: [
        "Duet",
        .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
        .product(name: "XCore", package: "x-kit"),
        .product(name: "Tagged", package: "swift-tagged"),
      ],
      swiftSettings: [.unsafeFlags(["-Xfrontend", "-warnings-as-errors"])],
    ),
    .testTarget(
      name: "DuetSQLTests",
      dependencies: ["DuetSQL", .product(name: "XExpect", package: "x-expect")],
    ),
  ],
)

// helpers

extension PackageDescription.Package.Dependency {
  static func package(_ commitish: String) -> Package.Dependency {
    let parts = commitish.split(separator: "@")
    return .package(
      url: "https://github.com/\(parts[0]).git",
      exact: .init(stringLiteral: "\(parts[1])"),
    )
  }
}
