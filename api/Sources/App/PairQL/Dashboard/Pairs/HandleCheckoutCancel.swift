import Foundation
import TypescriptPairQL

struct HandleCheckoutCancel: TypescriptPair {
  static var auth: ClientAuth = .none

  struct Input: TypescriptPairInput {
    var stripeCheckoutSessionid: String
  }
}

// resolver

extension HandleCheckoutCancel: Resolver {
  static func resolve(
    for input: Input,
    in context: DashboardContext
  ) async throws -> Output {
    let session = try await Current.stripe.getCheckoutSession(input.stripeCheckoutSessionid)
    let admin = try await Current.db.find(session.adminId)
    admin.subscriptionStatus = .signupCanceled
    try await Current.db.update(admin)
    Current.sendGrid.fireAndForget(.toJared("Checkout canceled", "admin: \(admin.id)"))
    return .success
  }
}
