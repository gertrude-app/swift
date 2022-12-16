// swift-tools-version:5.5

import PackageDescription

let package = Package(
  name: "XStripe",
  platforms: [.macOS(.v12)],
  products: [
    .library(name: "XStripe", targets: ["XStripe"]),
  ],
  dependencies: [
    .package(path: "../x-http"),
  ],
  targets: [
    .target(name: "XStripe", dependencies: [
      .product(name: "XHttp", package: "x-http"),
    ]),
  ]
)
