// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "PodcastRoute",
  platforms: [.macOS(.v10_15), .iOS(.v17)],
  products: [
    .library(name: "PodcastRoute", targets: ["PodcastRoute"]),
  ],
  dependencies: [
    // fork avoids swift-syntax transitive dep via case-paths
    .package(url: "https://github.com/gertrude-app/swift-url-routing", revision: "1cf1ca6"),
    .package(path: "../pairql"),
  ],
  targets: [
    .target(
      name: "PodcastRoute",
      dependencies: [
        .product(name: "URLRouting", package: "swift-url-routing"),
        .product(name: "PairQL", package: "pairql"),
      ],
      swiftSettings: [.unsafeFlags(["-Xfrontend", "-warnings-as-errors"])]
    ),
  ]
)
