import Foundation
import PairQL
import Vapor

struct CreateBillingPortalSession: Pair {
  static var auth: ClientAuth = .admin

  struct Output: PairOutput {
    var url: String
  }
}

// resolver

extension CreateBillingPortalSession: NoInputResolver {
  static func resolve(in context: AdminContext) async throws -> Output {
    guard let subscriptionId = context.admin.subscriptionId else {
      throw Abort(.badRequest)
    }

    let subscription = try await Current.stripe.getSubscription(subscriptionId.rawValue)
    let portal = try await Current.stripe.createBillingPortalSession(subscription.customer)
    return Output(url: portal.url)
  }
}
