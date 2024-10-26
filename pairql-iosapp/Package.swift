// swift-tools-version:5.10
import PackageDescription

let package = Package(
  name: "IOSRoute",
  platforms: [.macOS(.v10_15), .iOS(.v17)],
  products: [
    .library(name: "IOSRoute", targets: ["IOSRoute"]),
  ],
  dependencies: [
    // fork avoids swift-syntax transitive dep via case-paths
    .package(url: "https://github.com/gertrude-app/swift-url-routing", revision: "1cf1ca6"),
    .package(path: "../pairql"),
    .package(path: "../gertie"),
  ],
  targets: [
    .target(
      name: "IOSRoute",
      dependencies: [
        .product(name: "URLRouting", package: "swift-url-routing"),
        .product(name: "PairQL", package: "pairql"),
        .product(name: "GertieIOS", package: "gertie"),
      ],
      swiftSettings: [.unsafeFlags([
        "-Xfrontend", "-warn-concurrency",
        "-Xfrontend", "-enable-actor-data-race-checks",
        "-Xfrontend", "-warnings-as-errors",
      ])]
    ),
  ]
)
