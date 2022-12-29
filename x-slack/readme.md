# XSlack

A modest little **Slack Swift SDK**, with async/await.

## Usage

Send a simple text-only chat message:

```swift
import XSlack

let msg = Slack.Message(
  text: "Hello world!",
  channel: "#general",
  username: "XBot",
  emoji: .robotFace
)

let client = Slack.Client.live
let token = "xoxb-123-abc-yougettheidea"
let errMsg: String? = try await client.send(msg, token)
```

Send a **block-based** message:

```swift
let blockMsg = Slack.Message(
  blocks: [
    .header(text: "A Kitten!"),
    .divider,
    .image(url: URL(string: "https://cat.com/cat.png")!, altText: "cat"),
    .section(
      text: "section",
      accessory: .image(
        url: URL(string: "https://cat.com/cat.png")!,
        altText: "cat"
      )
    ),
  ],
  channel: "#general",
  username: "XBot",
  emoji: .robotFace
)

// [...]
let errMsg = try await client.send(blockMsg, token)
```

## Environment/Mocking/Testing

This library was designed to be used with the
[dependency injection approach from pointfree.co](https://www.pointfree.co/episodes/ep16-dependency-injection-made-easy):

```swift
import XSlack

struct Environment {
  var slackClient: Slack.Client
  // other dependencies...
}

extension Environment {
  static let live = Environment(slackClient: Slack.Client.live)
  static let mock = Environment(slackClient: Slack.Client.mock)
}

var Current = Environment.live

// 🎉 you can swap out your own mock implementation:
Current.slackClient.send = { _, _ in fatalError("should not be called") }
```

## Installation

Use SPM:

```diff
// swift-tools-version:5.5
import PackageDescription

let package = Package(
  name: "RadProject",
  products: [
    .library(name: "RadProject", targets: ["RadProject"]),
  ],
  dependencies: [
+   .package(url: "https://github.com/jaredh159/x-slack.git", from: "1.0.0")
  ],
  targets: [
    .target(name: "RadProject", dependencies: [
+     .product(name: "XSlack", package: "x-slack"),
    ]),
  ]
)
```
