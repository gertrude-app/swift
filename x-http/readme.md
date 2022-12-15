# XHttp

A zero-dependency, bare-bones Swift HTTP library, using `async/await`.

## Usage

Make a `GET` request, decoding the response:

```swift
import XHttp

struct XkcdComic: Decodable {
  let num: Int
  let title: String
  let month: String
  let year: String
}

let bobbyTables = try await HTTP.get(
  "https://xkcd.com/327/info.0.json",
  decoding: XkcdComic.self
)
```

Supports posting arbitrary JSON and decoding the response:

```swift
let slackResponse = try await HTTP.postJson(
  slack, // 👋 <-- some `Encodable` type instance
  to: "https://slack.com/api/chat.postMessage",
  decoding: SlackResponse.self
)
```

All methods allow passing headers, a handful of authorization types (bearer, basic), and
custom encoding/decoding strategies:

```swift
let slackResponse = try await HTTP.postJson(
  slack,
  to: "https://slack.com/api/chat.postMessage",
  decoding: SlackResponse.self,
  headers: ["X-Foo": "Bar"], // 👋 <-- custom headers
  auth: .bearer(token), // 👋 <-- authorization
  keyEncodingStrategy: .convertToSnakeCase, // 👋 <-- encoding strategy
  keyDecodingStrategy: .convertFromSnakeCase // 👋 <-- decoding strategy
)
```

Also includes a method for posting posting **x-www-form-urlencoded** data:

```swift
try await HTTP.postFormUrlencoded(
  ["payment_intent": "pi_abc123lolrofl"], // 👋 <-- url params
  to: "https://api.stripe.com/v1/refunds",
  decoding: Stripe.Api.Refund.self,
  auth: .basic(STRIPE_SECRET_KEY, ""),
  keyDecodingStrategy: .convertFromSnakeCase
)
```

All the methods have overloads allowing you to directly access to the `Data` and
`HTTPURLResponse` if you don't want to decode to a decodable type:

```swift
let (data, httpUrlResponse) = try await HTTP.get("https://xkcd.com/327/info.0.json")
let (data, httpUrlResponse) = try await HTTP.postJson(
  slack,
  to: "https://slack.com/api/chat.postMessage"
)
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
+   .package(url: "https://github.com/jaredh159/x-http.git", from: "1.0.0")
  ],
  targets: [
    .target(name: "RadProject", dependencies: [
+     .product(name: "XHttp", package: "x-http"),
    ]),
  ]
)
```

## Used by

A few basic higher-level client/sdk's built on top of `XHttp` include:

- [XSendGrid](https://github.com/jaredh159/x-sendgrid)
- [XSlack](https://github.com/jaredh159/x-slack)
- [XStripe](https://github.com/jaredh159/x-stripe)
