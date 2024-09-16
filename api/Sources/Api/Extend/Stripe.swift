import Vapor
import XStripe

extension Stripe.Api.CheckoutSession {
  var adminId: Admin.Id {
    get throws {
      guard let clientReferenceId else {
        with(dependency: \.logger)
          .error("No client reference in Stripe response")
        throw Abort(.internalServerError)
      }

      guard let uuid = UUID(uuidString: clientReferenceId) else {
        with(dependency: \.logger)
          .error("Invalid client reference in Stripe response")
        throw Abort(.internalServerError)
      }

      return .init(uuid)
    }
  }

  var adminUserSubscriptionId: Admin.SubscriptionId {
    get throws {
      guard let id = subscription else {
        with(dependency: \.logger)
          .error("No subscription ID in Stripe response")
        throw Abort(.internalServerError)
      }
      return .init(id)
    }
  }
}
