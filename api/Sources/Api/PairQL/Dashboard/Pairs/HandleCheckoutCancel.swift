import Foundation
import PairQL
import XCore

struct HandleCheckoutCancel: Pair {
  static let auth: ClientAuth = .admin

  struct Input: PairInput {
    var stripeCheckoutSessionId: String
  }
}

// resolver

extension HandleCheckoutCancel: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    let session = try await context.stripe.getCheckoutSession(input.stripeCheckoutSessionId)
    let detail = "admin: \(context.admin.id), session: \(try JSON.encode(session)))"
    Current.sendGrid.fireAndForget(.toJared("Checkout canceled", detail))
    return .success
  }
}
