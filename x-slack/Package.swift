// swift-tools-version:5.7
import PackageDescription

let package = Package(
  name: "XSlack",
  platforms: [.macOS(.v12)],
  products: [
    .library(name: "XSlack", targets: ["XSlack"]),
  ],
  dependencies: [
    .package(path: "../x-http"),
  ],
  targets: [
    .target(
      name: "XSlack",
      dependencies: [.product(name: "XHttp", package: "x-http")],
      swiftSettings: [.unsafeFlags([
        "-Xfrontend", "-warn-concurrency",
        "-Xfrontend", "-enable-actor-data-race-checks",
        "-Xfrontend", "-warnings-as-errors",
      ])]
    ),
    .testTarget(name: "XSlackTests", dependencies: ["XSlack"]),
  ]
)
