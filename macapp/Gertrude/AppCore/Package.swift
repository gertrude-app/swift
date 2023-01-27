// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "AppCore",
  platforms: [.macOS(.v11)],
  products: [
    .library(name: "AppCore", targets: ["AppCore"]),
  ],
  dependencies: [
    .package(
      name: "Starscream",
      url: "https://github.com/daltoniam/Starscream.git",
      from: "4.0.4"
    ),
    .package(
      name: "Sparkle",
      // @see: https://gist.github.com/jaredh159/5fafcdc04de9234ab4bab52897da7334
      url: "https://github.com/jaredh159/Sparkle",
      .exact("2.2.556")
    ),
    .package(
      name: "LaunchAtLogin",
      url: "https://github.com/sindresorhus/LaunchAtLogin",
      from: "4.2.0"
    ),
    .package(
      url: "https://github.com/pointfreeco/combine-schedulers",
      from: "0.5.3"
    ),
    .package(name: "Shared", path: "../../../shared"),
    .package(name: "MacAppRoute", path: "../../../pairql-macapp"),
    .package(name: "SharedCore", path: "../SharedCore"),
    .package(name: "Websocket", path: "../Websocket"),
  ],
  targets: [
    .target(
      name: "AppCore",
      dependencies: [
        "Starscream",
        "Sparkle",
        "Shared",
        "SharedCore",
        "MacAppRoute",
        "Websocket",
        "LaunchAtLogin",
        .product(name: "CombineSchedulers", package: "combine-schedulers"),
      ]
    ),
    .testTarget(
      name: "AppCoreTests",
      dependencies: ["AppCore"],
      exclude: ["__fixtures__/"]
    ),
  ]
)
