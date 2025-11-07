// swift-tools-version: 6.0
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
      swiftSettings: [.unsafeFlags(["-Xfrontend", "-warnings-as-errors"])],
    ),
    .testTarget(name: "XSlackTests", dependencies: ["XSlack"]),
  ],
)
