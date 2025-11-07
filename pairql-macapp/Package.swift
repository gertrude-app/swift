// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "MacAppRoute",
  platforms: [.macOS(.v10_15)],
  products: [
    .library(name: "MacAppRoute", targets: ["MacAppRoute"]),
  ],
  dependencies: [
    // fork avoids swift-syntax transitive dep via case-paths
    .package(url: "https://github.com/gertrude-app/swift-url-routing", revision: "1cf1ca6"),
    .package(path: "../pairql"),
    .package(path: "../gertie"),
    .package(path: "../x-expect"),
  ],
  targets: [
    .target(
      name: "MacAppRoute",
      dependencies: [
        .product(name: "URLRouting", package: "swift-url-routing"),
        .product(name: "PairQL", package: "pairql"),
        .product(name: "Gertie", package: "gertie"),
      ],
      swiftSettings: [.unsafeFlags(["-Xfrontend", "-warnings-as-errors"])],
    ),
    .testTarget(name: "MacAppRouteTests", dependencies: [
      .target(name: "MacAppRoute"),
      .product(name: "XExpect", package: "x-expect"),
    ]),
  ],
)
