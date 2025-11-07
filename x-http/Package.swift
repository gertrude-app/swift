// swift-tools-version: 6.0
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
      swiftSettings: [.unsafeFlags(["-Xfrontend", "-warnings-as-errors"])],
    ),
    .testTarget(
      name: "XHttpTests",
      dependencies: ["XHttp"],
    ),
  ],
)
