// swift-tools-version:5.10
import PackageDescription

let package = Package(
  name: "Gertie",
  platforms: [.macOS(.v10_15), .iOS(.v17)],
  products: [
    .library(name: "Gertie", targets: ["Gertie"]),
    .library(name: "GertieIOS", targets: ["GertieIOS"]),
  ],
  dependencies: [
    .package("jaredh159/swift-tagged@0.8.2"),
    .package(path: "../x-kit"),
    .package(path: "../x-expect"),
  ],
  targets: [
    .target(
      name: "Gertie",
      dependencies: [
        .product(name: "XCore", package: "x-kit"),
        .product(name: "TaggedTime", package: "swift-tagged"),
      ],
      swiftSettings: [.unsafeFlags([
        "-Xfrontend", "-warn-concurrency",
        "-Xfrontend", "-enable-actor-data-race-checks",
        "-Xfrontend", "-warnings-as-errors",
      ])]
    ),
    .testTarget(
      name: "GertieTests",
      dependencies: [
        "Gertie",
        .product(name: "XExpect", package: "x-expect"),
      ]
    ),
    .target(
      name: "GertieIOS",
      dependencies: [],
      swiftSettings: [.unsafeFlags([
        "-Xfrontend", "-warn-concurrency",
        "-Xfrontend", "-enable-actor-data-race-checks",
        "-Xfrontend", "-warnings-as-errors",
      ])]
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
