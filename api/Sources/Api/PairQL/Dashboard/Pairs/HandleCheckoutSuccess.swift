import Dependencies
import Foundation
import PairQL

struct HandleCheckoutSuccess: Pair {
  static let auth: ClientAuth = .admin

  struct Input: PairInput {
    var stripeCheckoutSessionId: String
  }
}

// resolver

extension HandleCheckoutSuccess: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    @Dependency(\.date.now) var now
    @Dependency(\.stripe) var stripe

    let session = try await stripe.getCheckoutSession(input.stripeCheckoutSessionId)
    var admin = try await context.db.find(session.adminId)
    let subscriptionId = try session.adminUserSubscriptionId
    let subscription = try await stripe.getSubscription(subscriptionId.rawValue)
    switch (admin.subscriptionStatus, subscription.status) {

    case (.trialing, .active),
         (.trialExpiringSoon, .active),
         (.overdue, .active),
         (.paid, .active), // <-- happens when stripe webhook received before
         (.unpaid, .active):
      admin.subscriptionStatus = .paid
      admin.subscriptionId = subscriptionId
      admin.subscriptionStatusExpiration = now + .days(33)
      try await context.db.update(admin)

    case (let adminStatus, let stripeStatus):
      unexpected(
        "1146b93f",
        context,
        "admin: .\(adminStatus), stripe: .\(stripeStatus), subs: \(subscriptionId)"
      )
    }

    return .success
  }
}
