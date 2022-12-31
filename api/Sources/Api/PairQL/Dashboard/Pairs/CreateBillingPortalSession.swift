import Foundation
import TypescriptPairQL
import Vapor

struct CreateBillingPortalSession: TypescriptPair {
  static var auth: ClientAuth = .admin

  struct Output: TypescriptPairOutput {
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
