import Foundation
import PairQL
import Vapor
import XStripe

struct StripeUrl: Pair {
  static let auth: ClientAuth = .admin
  struct Output: PairOutput {
    var url: String
  }
}

// resolver

extension StripeUrl: NoInputResolver {
  static func resolve(in context: AdminContext) async throws -> Output {
    switch (context.admin.subscriptionStatus, context.admin.subscriptionId) {

    case (.trialing, nil),
         (.trialExpiringSoon, nil),
         (.overdue, nil),
         (.unpaid, nil):
      return .init(url: try await checkoutSessionUrl(for: context))

    case (.paid, .some(let subscription)),
         (.overdue, .some(let subscription)),
         (.unpaid, .some(let subscription)):
      return .init(url: try await billingPortalSessionUrl(for: subscription, in: context))

    // should never happen...
    case (let status, let subscription):
      unexpected("65554aa1", context, ".\(status), \(subscription ?? "nil")")
      if let subscription {
        return .init(url: try await billingPortalSessionUrl(for: subscription, in: context))
      } else {
        return .init(url: try await checkoutSessionUrl(for: context))
      }
    }
  }
}

// helpers

private func checkoutSessionUrl(for context: AdminContext) async throws -> String {
  let sessionData = Stripe.CheckoutSessionData(
    successUrl: "\(context.dashboardUrl)/checkout-success?session_id={CHECKOUT_SESSION_ID}",
    cancelUrl: "\(context.dashboardUrl)/checkout-cancel?session_id={CHECKOUT_SESSION_ID}",
    lineItems: [.init(quantity: 1, priceId: context.env.stripe.subscriptionPriceId)],
    mode: .subscription,
    clientReferenceId: context.admin.id.lowercased,
    customerEmail: context.admin.email.rawValue,
    // below params are for no-credit card trials, which we don't do any more
    // since we don't send them to stripe at all when they sign up
    trialPeriodDays: nil,
    trialEndBehavior: nil,
    paymentMethodCollection: nil
  )

  let session = try await context.stripe.createCheckoutSession(sessionData)
  guard let url = session.url else {
    Current.sendGrid.fireAndForget(.unexpected("b66e1eaf", "admin: \(context.admin.id)"))
    throw Abort(.internalServerError)
  }
  return url
}

private func billingPortalSessionUrl(
  for subscriptionId: Admin.SubscriptionId,
  in context: AdminContext
) async throws -> String {
  let subscription = try await context.stripe.getSubscription(subscriptionId.rawValue)
  let portal = try await context.stripe.createBillingPortalSession(subscription.customer)
  return portal.url
}
