import Foundation
import TypescriptPairQL

struct HandleCheckoutCancel: TypescriptPair {
  static var auth: ClientAuth = .none

  struct Input: TypescriptPairInput {
    var stripeCheckoutSessionId: String
  }
}

// resolver

extension HandleCheckoutCancel: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let session = try await Current.stripe.getCheckoutSession(input.stripeCheckoutSessionId)
    let admin = try await Current.db.find(session.adminId)
    admin.subscriptionStatus = .signupCanceled
    try await Current.db.update(admin)
    Current.sendGrid.fireAndForget(.toJared("Checkout canceled", "admin: \(admin.id)"))
    return .success
  }
}
