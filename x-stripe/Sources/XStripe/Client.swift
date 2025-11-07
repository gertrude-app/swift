import Foundation
import XHttp

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

public extension Stripe {
  struct Client: Sendable {
    public var createPaymentIntent: @Sendable (
      Int,
      Stripe.Api.Currency,
      [String: String]
    ) async throws -> Stripe.Api.PaymentIntent
    public var cancelPaymentIntent: @Sendable (String) async throws -> Stripe.Api.PaymentIntent
    public var createRefund: @Sendable (String) async throws -> Stripe.Api.Refund
    public var getCheckoutSession: @Sendable (String) async throws -> Stripe.Api.CheckoutSession
    public var createCheckoutSession: @Sendable (CheckoutSessionData) async throws
      -> Stripe.Api.CheckoutSession
    public var getSubscription: @Sendable (String) async throws -> Stripe.Api.Subscription
    public var createBillingPortalSession: @Sendable (String) async throws
      -> Stripe.Api.BillingPortalSession

    public init(
      createPaymentIntent: @Sendable @escaping (
        Int,
        Stripe.Api.Currency,
        [String: String]
      ) async throws -> Stripe.Api.PaymentIntent,
      cancelPaymentIntent: @Sendable @escaping (String) async throws -> Stripe.Api.PaymentIntent,
      createRefund: @Sendable @escaping (String) async throws -> Stripe.Api.Refund,
      getCheckoutSession: @Sendable @escaping (String) async throws -> Stripe.Api.CheckoutSession,
      createCheckoutSession: @Sendable @escaping (CheckoutSessionData) async throws
        -> Stripe.Api.CheckoutSession,
      getSubscription: @Sendable @escaping (String) async throws -> Stripe.Api.Subscription,
      createBillingPortalSession: @Sendable @escaping (String) async throws
        -> Stripe.Api.BillingPortalSession,
    ) {
      self.createPaymentIntent = createPaymentIntent
      self.cancelPaymentIntent = cancelPaymentIntent
      self.createRefund = createRefund
      self.getCheckoutSession = getCheckoutSession
      self.createCheckoutSession = createCheckoutSession
      self.getSubscription = getSubscription
      self.createBillingPortalSession = createBillingPortalSession
    }
  }
}

public extension Stripe.Client {
  static func live(secretKey: String) -> Stripe.Client {
    Stripe.Client(
      createPaymentIntent: { amount, currency, metadata in
        try await _createPaymentIntent(
          amountInCents: amount,
          currency: currency,
          metadata: metadata,
          secretKey: secretKey,
        )
      },
      cancelPaymentIntent: { id in
        try await _cancelPaymentIntent(id: id, secretKey: secretKey)
      },
      createRefund: { id in
        try await _createRefund(paymentIntentId: id, secretKey: secretKey)
      },
      getCheckoutSession: { id in
        try await _getCheckoutSession(id: id, secretKey: secretKey)
      },
      createCheckoutSession: { data in
        try await _createCheckoutSession(data: data, secretKey: secretKey)
      },
      getSubscription: { id in
        try await _getSubscription(id: id, secretKey: secretKey)
      },
      createBillingPortalSession: { id in
        try await _createBillingPortalSession(customerId: id, secretKey: secretKey)
      },
    )
  }
}

// implementations

private func _createBillingPortalSession(
  customerId: String,
  secretKey: String,
) async throws -> Stripe.Api.BillingPortalSession {
  let (data, res) = try await HTTP.postFormUrlencoded(
    ["customer": customerId],
    to: "https://api.stripe.com/v1/billing_portal/sessions",
    auth: .basic(secretKey, ""),
  )
  return try await decode(Stripe.Api.BillingPortalSession.self, data: data, response: res)
}

private func _getSubscription(
  id: String,
  secretKey: String,
) async throws -> Stripe.Api.Subscription {
  let (data, response) = try await HTTP.get(
    "https://api.stripe.com/v1/subscriptions/\(id)",
    auth: .basic(secretKey, ""),
  )
  return try await decode(Stripe.Api.Subscription.self, data: data, response: response)
}

private func _getCheckoutSession(
  id: String,
  secretKey: String,
) async throws -> Stripe.Api.CheckoutSession {
  let (data, response) = try await HTTP.get(
    "https://api.stripe.com/v1/checkout/sessions/\(id)",
    auth: .basic(secretKey, ""),
  )
  return try await decode(Stripe.Api.CheckoutSession.self, data: data, response: response)
}

private func _createCheckoutSession(
  data: Stripe.CheckoutSessionData,
  secretKey: String,
) async throws -> Stripe.Api.CheckoutSession {
  var params = [
    "success_url": data.successUrl,
    "cancel_url": data.cancelUrl,
    "mode": data.mode.rawValue,
  ]

  for (index, lineItem) in data.lineItems.enumerated() {
    params["line_items[\(index)][quantity]"] = String(lineItem.quantity)
    params["line_items[\(index)][price]"] = lineItem.priceId
  }

  if let customerEmail = data.customerEmail {
    params["customer_email"] = customerEmail.replacingOccurrences(of: "+", with: "%2b")
  }

  if let trialPeriodDays = data.trialPeriodDays {
    params["subscription_data[trial_period_days]"] = String(trialPeriodDays)
  }

  if let endBehavior = data.trialEndBehavior {
    params["subscription_data[trial_settings][end_behavior][missing_payment_method]"] = endBehavior
      .rawValue
  }

  if let collection = data.paymentMethodCollection {
    params["payment_method_collection"] = collection.rawValue
  }

  if let clientReferenceId = data.clientReferenceId {
    params["client_reference_id"] = clientReferenceId
  }

  let (data, response) = try await HTTP.postFormUrlencoded(
    params,
    to: "https://api.stripe.com/v1/checkout/sessions",
    auth: .basic(secretKey, ""),
  )

  return try await decode(Stripe.Api.CheckoutSession.self, data: data, response: response)
}

private func _createRefund(
  paymentIntentId: String,
  secretKey: String,
) async throws -> Stripe.Api.Refund {
  let (data, response) = try await HTTP.postFormUrlencoded(
    ["payment_intent": paymentIntentId],
    to: "https://api.stripe.com/v1/refunds",
    auth: .basic(secretKey, ""),
  )
  return try await decode(Stripe.Api.Refund.self, data: data, response: response)
}

private func _createPaymentIntent(
  amountInCents: Int,
  currency: Stripe.Api.Currency,
  metadata: [String: String],
  secretKey: String,
) async throws -> Stripe.Api.PaymentIntent {
  var formData = [
    "amount": "\(amountInCents)",
    "currency": "\(currency.rawValue)",
  ]

  for (key, value) in metadata {
    formData["metadata[\(key)]"] = value
  }

  let (data, response) = try await HTTP.postFormUrlencoded(
    formData,
    to: "https://api.stripe.com/v1/payment_intents",
    auth: .basic(secretKey, ""),
  )

  return try await decode(Stripe.Api.PaymentIntent.self, data: data, response: response)
}

private func _cancelPaymentIntent(
  id: String,
  secretKey: String,
) async throws -> Stripe.Api.PaymentIntent {
  let (data, response) = try await HTTP.post(
    "https://api.stripe.com/v1/payment_intents/\(id)/cancel",
    auth: .basic(secretKey, ""),
  )
  return try await decode(Stripe.Api.PaymentIntent.self, data: data, response: response)
}

struct WrappedError: Decodable {
  let error: Stripe.Api.Error
}

private func decode<T: Decodable>(
  _: T.Type,
  data: Data,
  response: HTTPURLResponse,
) async throws -> T {
  let decoder = JSONDecoder()
  decoder.keyDecodingStrategy = .convertFromSnakeCase
  if response.statusCode >= 300 {
    if let stripeError = try? decoder.decode(WrappedError.self, from: data) {
      throw stripeError.error
    } else {
      throw Stripe.Api.Error(
        type: "unknown_error",
        message: String(data: data, encoding: .utf8) ?? nil,
      )
    }
  }
  do {
    return try decoder.decode(T.self, from: data)
  } catch {
    throw HttpError.decodingError(error, String(data: data, encoding: .utf8) ?? "")
  }
}

// mock

public extension Stripe.Client {
  static let mock = Stripe.Client(
    createPaymentIntent: { _, _, _ in
      .init(id: "pi_mock_id", clientSecret: "pi_mock_secret")
    },
    cancelPaymentIntent: { _ in
      .init(id: "pi_mock_id", clientSecret: "pi_mock_secret")
    },
    createRefund: { _ in
      .init(id: "re_mock_id")
    },
    getCheckoutSession: { _ in
      .init(id: "cs_123", url: nil, subscription: "sub_123", clientReferenceId: nil)
    },
    createCheckoutSession: { _ in
      .init(id: "cs_123", url: "/checkout.session/url", subscription: nil, clientReferenceId: nil)
    },
    getSubscription: { _ in
      .init(id: "sub_123", status: .trialing, customer: "cus_123", currentPeriodEnd: 0)
    },
    createBillingPortalSession: { _ in
      .init(id: "bps_123", url: "/billing_portal.session/url")
    },
  )
}
