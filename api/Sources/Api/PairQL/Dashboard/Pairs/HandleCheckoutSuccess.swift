import Foundation
import PairQL

struct AdminAuth: PairOutput {
  var token: AdminToken.Value
  var adminId: Admin.Id
}

struct HandleCheckoutSuccess: Pair {
  static var auth: ClientAuth = .none

  struct Input: PairInput {
    var stripeCheckoutSessionId: String
  }

  typealias Output = AdminAuth
}

// resolver

extension HandleCheckoutSuccess: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let session = try await Current.stripe.getCheckoutSession(input.stripeCheckoutSessionId)
    let admin = try await Current.db.find(session.adminId)
    let subscriptionId = try session.adminUserSubscriptionId
    admin.subscriptionId = subscriptionId

    let subscription = try await Current.stripe.getSubscription(subscriptionId.rawValue)
    if admin.subscriptionStatus != .complimentary {
      admin.subscriptionStatus = .init(stripeSubscriptionStatus: subscription.status)
    }

    try await Current.db.update(admin)
    let token = try await Current.db.create(AdminToken(adminId: admin.id))
    return Output(token: token.value, adminId: admin.id)
  }
}
