import Dependencies
import Foundation
import PairQL
import Vapor
import XStripe

struct StripeUrl: Pair {
  static let auth: ClientAuth = .parent
  struct Output: PairOutput {
    var url: String
  }
}

// resolver

extension StripeUrl: NoInputResolver {
  static func resolve(in context: AdminContext) async throws -> Output {
    switch (context.parent.subscriptionStatus, context.parent.subscriptionId) {

    case (.trialing, nil),
         (.trialExpiringSoon, nil),
         (.overdue, nil),
         (.unpaid, nil):
      return try await .init(url: checkoutSessionUrl(for: context))

    case (.paid, .some(let subscription)),
         (.overdue, .some(let subscription)),
         (.unpaid, .some(let subscription)):
      return try await .init(url: billingPortalSessionUrl(for: subscription, in: context))

    // should never happen...
    case (let status, let subscription):
      unexpected("65554aa1", context, ".\(status), \(subscription ?? "nil")")
      if let subscription {
        return try await .init(url: billingPortalSessionUrl(for: subscription, in: context))
      } else {
        return try await .init(url: checkoutSessionUrl(for: context))
      }
    }
  }
}

// helpers

private func checkoutSessionUrl(for context: AdminContext) async throws -> String {
  let sessionData = Stripe.CheckoutSessionData(
    successUrl: "\(context.dashboardUrl)/checkout-success?session_id={CHECKOUT_SESSION_ID}",
    cancelUrl: "\(context.dashboardUrl)/checkout-cancel?session_id={CHECKOUT_SESSION_ID}",
    lineItems: [.init(quantity: 1, priceId: context.parent.stripePriceId)],
    mode: .subscription,
    clientReferenceId: context.parent.id.lowercased,
    customerEmail: context.parent.email.rawValue,
    // below params are for no-credit card trials, which we don't do any more
    // since we don't send them to stripe at all when they sign up
    trialPeriodDays: nil,
    trialEndBehavior: nil,
    paymentMethodCollection: nil
  )

  let session = try await with(dependency: \.stripe)
    .createCheckoutSession(sessionData)

  guard let url = session.url else {
    with(dependency: \.postmark)
      .unexpected("b66e1eaf", "admin: \(context.parent.id)")
    throw Abort(.internalServerError)
  }
  return url
}

private func billingPortalSessionUrl(
  for subscriptionId: Admin.SubscriptionId,
  in context: AdminContext
) async throws -> String {
  @Dependency(\.stripe) var stripe
  let subscription = try await stripe.getSubscription(subscriptionId.rawValue)
  let portal = try await stripe.createBillingPortalSession(subscription.customer)
  return portal.url
}
