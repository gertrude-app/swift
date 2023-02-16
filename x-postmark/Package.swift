// swift-tools-version:5.7
import PackageDescription

let package = Package(
  name: "XPostmark",
  platforms: [.macOS(.v12)],
  products: [
    .library(name: "XPostmark", targets: ["XPostmark"]),
  ],
  dependencies: [
    .package(path: "../x-http"),
  ],
  targets: [
    .target(name: "XPostmark", dependencies: [
      .product(name: "XHttp", package: "x-http"),
    ]),
  ]
)
