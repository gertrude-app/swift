# XStripe

A very bare-bones **Swift Stripe Client/SDK**, written with async/await.

## Anti-pitch

This library was written to cover _only the use-cases for two_ of my vapor apps. It's open
source, and you're welcome to use it, but it has some major limitations currently --
including that it only supports 7 api operations, and only supports `USD` currency. That
said, if it looks promising, and you'd like to see it broadened, open an issue, or open a
PR, I'm open to making it more general-purpose.

## Usage

_Create_ a **payment intent**:

```swift
import XStripe

let amountInCents = 499;
let additionalMetadata = ["orderId": "internal-123-abc"]
let stripeSecretKey = "sk_sosecret-123"

let paymentIntent = try await Stripe.Client().createPaymentIntent(
  amountInCents,
  .USD,
  additionalMetadata,
  stripSecretKey
)
```

_Cancel_ a **payment intent**:

```swift
// [...]
let paymentIntent = try await Stripe.Client().cancelPaymentIntent("pi_123", secretKey)
```

_Create_ a **refund**:

```swift
// [...]
let refund = try await Stripe.Client().createRefund("pi_123", secretKey)
```

_Create_ a **checkout session**:

```swift
// [...]
let sessionData = Stripe.CheckoutSessionData(
  successUrl: "https://site.com/checkout-success?session_id={CHECKOUT_SESSION_ID}",
  cancelUrl: "https://site.com/checkout-cancel",
  lineItems: [.init(quantity: 1, priceId: "price_123abc")],
  mode: .subscription,
  clientReferenceId: "your-internal-reference-id", // optional
  customerEmail: "suzy@q.com", // optional
  trialPeriodDays: 30 // optional
)
let session = try await Stripe.Client().createCheckoutSession(sessionData, secretKey)
```

_Get_ a **checkout session**:

```swift
// [...]
let session = try await Stripe.Client().getCheckoutSession("cs_123", secretKey)
```

_Get_ a **subscription**:

```swift
// [...]
let subscription = try await Stripe.Client().getSubscription("sub_123", secretKey)
```

_Create_ a **billing portal sesssion**:

```swift
// [...]
let session = try await Stripe.Client().createBillingPortalSession("bps_123", secretKey)
```

## Environment/Mocking/Testing

This library was designed to be used with the
[dependency injection approach from pointfree.co](https://www.pointfree.co/episodes/ep16-dependency-injection-made-easy):

```swift
import XStripe

struct Environment {
  var stripeClient: Stripe.Client
  // other dependencies...
}

extension Environment {
  static let live = Environment(stripeClient: Stripe.Client.live)
  static let mock = Environment(stripeClient: Stripe.Client.mock)
}

var Current = Environment.live

// 🎉 you can swap out your own mock implementation:
Current.stripeClient.createRefund = { _, _ in fatalError("should not be called") }
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
+   .package(url: "https://github.com/jaredh159/x-stripe.git", from: "1.0.0")
  ],
  targets: [
    .target(name: "RadProject", dependencies: [
+     .product(name: "XStripe", package: "x-stripe"),
    ]),
  ]
)
```
