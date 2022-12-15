# XSendGrid

A modest little **SendGrid Swift SDK**, with async/await.

## Usage

Send a basic _html_ email.

```swift
import XSendGrid

let email = SendGrid.Email(
  to: "betty@example.com",
  from: "amir@example.com",
  subject: "Ms. Fluff's birthday",
  html: "<h1>You're invited!</h1>"
)

let client = SendGrid.Client.live
let apiKey = "sg_123sosecret"
let responseData = try await client.send(email, apiKey)
```

Send a _plain text_ email:

```swift
let email = SendGrid.Email(
  to: "betty@example.com",
  from: "amir@example.com",
  subject: "Ms. Fluff's birthday",
  text: "You're invited!" // 👋 `text` instead of `html`
)

// [...]
let responseData = try await client.send(email, apiKey)
```

Add an _attachment_:

```swift
var email = SendGrid.Email(/* [...] */)

// 👋 optionally add one or more attachments
email.attachments = [.init(data: fileData, filename: "ms-fluff.gif")]

// [...]
let responseData = try await client.send(email, apiKey)
```

## Environment/Mocking/Testing

This library was designed to be used with the
[dependency injection approach from pointfree.co](https://www.pointfree.co/episodes/ep16-dependency-injection-made-easy):

```swift
import XSendGrid

struct Environment {
  var sendGridClient: SendGrid.Client
  // other dependencies...
}

extension Environment {
  static let live = Environment(sendGridClient: SendGrid.Client.live)
  static let mock = Environment(sendGridClient: SendGrid.Client.mock)
}

var Current = Environment.live

// you can swap out your own mock implementation:
Current.sendGridClient.send = { _, _ in fatalError("shouldn't be called") }
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
+   .package(url: "https://github.com/jaredh159/x-sendgrid.git", from: "1.0.0")
  ],
  targets: [
    .target(name: "RadProject", dependencies: [
+     .product(name: "XSendGrid", package: "x-sendgrid"),
    ]),
  ]
)
```
