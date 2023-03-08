// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "Cli",
  platforms: [.macOS(.v10_15)],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
    .package(path: "../typescript"),
    .package(path: "../rewrite/App"),
  ],
  targets: [
    .executableTarget(name: "Cli", dependencies: [
      .product(name: "ArgumentParser", package: "swift-argument-parser"),
      .product(name: "TypeScript", package: "typescript"),
      .product(name: "MenuBar", package: "App"),
    ]),
  ]
)
