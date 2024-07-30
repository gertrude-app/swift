// swift-tools-version:5.7
import PackageDescription

let package = Package(
  name: "PairQL",
  platforms: [.macOS(.v10_15)],
  products: [
    .library(name: "PairQL", targets: ["PairQL"]),
  ],
  dependencies: [
    .package("pointfreeco/swift-url-routing@0.5.0"),
    .package(path: "../x-expect"),
  ],
  targets: [
    .target(
      name: "PairQL",
      dependencies: [.product(name: "URLRouting", package: "swift-url-routing")],
      swiftSettings: [.unsafeFlags([
        "-Xfrontend", "-warn-concurrency",
        "-Xfrontend", "-enable-actor-data-race-checks",
        "-Xfrontend", "-warnings-as-errors",
      ])]
    ),
    .testTarget(name: "PairQLTests", dependencies: [
      .target(name: "PairQL"),
      .product(name: "XExpect", package: "x-expect"),
    ]),
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
