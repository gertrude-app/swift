// swift-tools-version:5.5
import PackageDescription

let package = Package(
  name: "api",
  platforms: [
    .macOS(.v12),
  ],
  dependencies: [
    .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
  ],
  targets: [
    .target(
      name: "App",
      dependencies: [.product(name: "Vapor", package: "vapor")],
      swiftSettings: [
        .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release)),
      ]
    ),
    .executableTarget(name: "Run", dependencies: [.target(name: "App")]),
    .testTarget(name: "AppTests", dependencies: [
      .target(name: "App"),
      .product(name: "XCTVapor", package: "vapor"),
    ]),
  ]
)
