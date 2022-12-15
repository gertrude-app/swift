// swift-tools-version:5.5

import PackageDescription

let package = Package(
  name: "XHttp",
  platforms: [.macOS(.v12)],
  products: [
    .library(name: "XHttp", targets: ["XHttp"]),
  ],
  dependencies: [],
  targets: [
    .target(name: "XHttp", dependencies: []),
    .testTarget(name: "XHttpTests", dependencies: ["XHttp"]),
  ]
)
