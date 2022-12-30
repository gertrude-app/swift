import Foundation
import TypescriptPairQL
import Vapor
import XStripe

struct GetCheckoutUrl: TypescriptPair {
  static var auth: ClientAuth = .admin

  struct Input: TypescriptPairInput {
    var adminId: Admin.Id
  }

  struct Output: TypescriptPairOutput {
    let url: String?
  }
}

// resolver

extension GetCheckoutUrl: Resolver {
  static func resolve(
    with input: Input,
    in context: DashboardContext
  ) async throws -> Output {
    let admin = try await Current.db.find(input.adminId)

    let sessionData = Stripe.CheckoutSessionData(
      successUrl: "\(context.dashboardUrl)/checkout-success?session_id={CHECKOUT_SESSION_ID}",
      cancelUrl: "\(context.dashboardUrl)/checkout-cancel?session_id={CHECKOUT_SESSION_ID}",
      lineItems: [.init(quantity: 1, priceId: Env.STRIPE_SUBSCRIPTION_PRICE_ID)],
      mode: .subscription,
      clientReferenceId: admin.id.lowercased,
      customerEmail: admin.email.rawValue,
      trialPeriodDays: 60,
      // following params allow for no credit card required
      trialEndBehavior: .createInvoice,
      paymentMethodCollection: .ifRequired
    )

    let session = try await Current.stripe.createCheckoutSession(sessionData)
    guard let url = session.url else {
      // TODO: logger
      // Current.logger.error("created stripe checkout session, but received no url")
      throw Abort(.internalServerError)
    }

    return Output(url: url)
  }
}
