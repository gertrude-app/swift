import Vapor
import XStripe

extension Stripe.Api.CheckoutSession {
  var adminId: Admin.Id {
    get throws {
      guard let clientReferenceId = clientReferenceId else {
        Current.logger.error("No client reference in Stripe response")
        throw Abort(.internalServerError)
      }

      guard let uuid = UUID(uuidString: clientReferenceId) else {
        Current.logger.error("Invalid client reference in Stripe response")
        throw Abort(.internalServerError)
      }

      return .init(rawValue: uuid)
    }
  }

  var adminUserSubscriptionId: Admin.SubscriptionId {
    get throws {
      guard let id = subscription else {
        Current.logger.error("No subscription ID in Stripe response")
        throw Abort(.internalServerError)
      }
      return .init(rawValue: id)
    }
  }
}

extension Admin.SubscriptionStatus {
  init(stripeSubscriptionStatus stripeStatus: Stripe.Api.Subscription.Status) {
    switch stripeStatus {
    case .incomplete:
      self = .incomplete
    case .incompleteExpired:
      self = .incompleteExpired
    case .trialing:
      self = .trialing
    case .active:
      self = .active
    case .pastDue:
      self = .pastDue
    case .canceled:
      self = .canceled
    case .unpaid:
      self = .unpaid
    }
  }
}
