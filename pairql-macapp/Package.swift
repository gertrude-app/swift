// swift-tools-version:5.7
import PackageDescription

let package = Package(
  name: "MacAppRoute",
  platforms: [.macOS(.v10_15)],
  products: [
    .library(name: "MacAppRoute", targets: ["MacAppRoute"]),
  ],
  dependencies: [
    .package("pointfreeco/swift-url-routing@0.5.0"),
    .package(path: "../pairql"),
    .package(path: "../gertie"),
    .package(path: "../x-expect"),
  ],
  targets: [
    .target(name: "MacAppRoute", dependencies: [
      .product(name: "URLRouting", package: "swift-url-routing"),
      .product(name: "PairQL", package: "pairql"),
      .product(name: "Gertie", package: "gertie"),
    ]),
    .testTarget(name: "MacAppRouteTests", dependencies: [
      .target(name: "MacAppRoute"),
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
