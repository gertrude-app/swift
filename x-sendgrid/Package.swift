// swift-tools-version:5.7
import PackageDescription

let package = Package(
  name: "XSendGrid",
  platforms: [.macOS(.v12)],
  products: [
    .library(name: "XSendGrid", targets: ["XSendGrid"]),
  ],
  dependencies: [
    .package(path: "../x-http"),
    .package(url: "https://github.com/pointfreeco/swift-nonempty.git", from: "0.5.0"),
  ],
  targets: [
    .target(
      name: "XSendGrid",
      dependencies: [
        .product(name: "XHttp", package: "x-http"),
        .product(name: "NonEmpty", package: "swift-nonempty"),
      ],
      swiftSettings: [.unsafeFlags([
        "-Xfrontend", "-warn-concurrency",
        "-Xfrontend", "-enable-actor-data-race-checks",
        "-Xfrontend", "-warnings-as-errors",
      ])]
    ),
  ]
)
