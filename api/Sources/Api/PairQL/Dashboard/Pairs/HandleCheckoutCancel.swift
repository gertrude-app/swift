import Dependencies
import Foundation
import PairQL
import XCore

struct HandleCheckoutCancel: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var stripeCheckoutSessionId: String
  }
}

// resolver

extension HandleCheckoutCancel: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    let session = try await with(dependency: \.stripe)
      .getCheckoutSession(input.stripeCheckoutSessionId)

    let detail = try "admin: \(context.parent.id), session: \(JSON.encode(session)))"
    with(dependency: \.postmark).toSuperAdmin("Checkout canceled", detail)

    return .success
  }
}
