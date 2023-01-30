// swift-tools-version:5.7
import PackageDescription

let package = Package(
  name: "Websocket",
  platforms: [.macOS(.v11)],
  products: [
    .library(name: "Websocket", targets: ["Websocket"]),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/combine-schedulers", from: "0.5.3"),
    .package(url: "https://github.com/daltoniam/Starscream.git", from: "4.0.4"),
    .package(name: "Shared", path: "../../../shared"),
    .package(name: "XKit", path: "../../../x-kit"),
  ],
  targets: [
    .target(
      name: "Websocket",
      dependencies: [
        .product(name: "CombineSchedulers", package: "combine-schedulers"),
        .product(name: "Shared", package: "Shared"),
        .product(name: "XCore", package: "XKit"),
        "Starscream",
      ]
    ),
    .testTarget(
      name: "WebsocketTests",
      dependencies: [
        "Websocket",
        "Starscream",
        "Shared",
        .product(name: "CombineSchedulers", package: "combine-schedulers"),
      ]
    ),
  ]
)
