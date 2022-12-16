import Foundation
import TypescriptPairQL

struct AdminAuth: TypescriptPairOutput {
  var token: UUID
  var adminId: UUID
}

struct HandleCheckoutSuccess: TypescriptPair {
  static var auth: ClientAuth = .none

  struct Input: TypescriptPairInput {
    var stripeCheckoutSessionid: String
  }

  typealias Output = AdminAuth
}

// resolver

extension HandleCheckoutSuccess: Resolver {
  static func resolve(
    for input: Input,
    in context: DashboardContext
  ) async throws -> Output {
    let session = try await Current.stripe.getCheckoutSession(input.stripeCheckoutSessionid)
    let admin = try await Current.db.find(session.adminId)
    let subscriptionId = try session.adminUserSubscriptionId
    admin.subscriptionId = subscriptionId

    let subscription = try await Current.stripe.getSubscription(subscriptionId.rawValue)
    if admin.subscriptionStatus != .complimentary {
      admin.subscriptionStatus = .init(stripeSubscriptionStatus: subscription.status)
    }

    try await Current.db.update(admin)
    let token = try await Current.db.create(AdminToken(adminId: admin.id))
    return Output(token: token.value.rawValue, adminId: admin.id.rawValue)
  }
}
