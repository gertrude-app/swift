// swift-tools-version:5.7
import PackageDescription

let package = Package(
  name: "XHttp",
  platforms: [.macOS(.v12)],
  products: [
    .library(name: "XHttp", targets: ["XHttp"]),
  ],
  dependencies: [],
  targets: [
    .target(
      name: "XHttp",
      dependencies: [],
      swiftSettings: [.unsafeFlags([
        "-Xfrontend", "-warn-concurrency",
        "-Xfrontend", "-enable-actor-data-race-checks",
        "-Xfrontend", "-warnings-as-errors",
      ])]
    ),
    .testTarget(
      name: "XHttpTests",
      dependencies: ["XHttp"]
    ),
  ]
)
