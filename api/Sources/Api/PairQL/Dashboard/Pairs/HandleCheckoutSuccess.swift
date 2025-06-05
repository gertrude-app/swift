import Dependencies
import Foundation
import PairQL

struct HandleCheckoutSuccess: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var stripeCheckoutSessionId: String
  }
}

// resolver

extension HandleCheckoutSuccess: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    @Dependency(\.date.now) var now
    @Dependency(\.stripe) var stripe

    let session = try await stripe.getCheckoutSession(input.stripeCheckoutSessionId)
    var parent = try await context.db.find(session.parentId)
    let subscriptionId = try session.parentSubscriptionId
    let subscription = try await stripe.getSubscription(subscriptionId.rawValue)
    switch (parent.subscriptionStatus, subscription.status) {

    case (.trialing, .active),
         (.trialExpiringSoon, .active),
         (.overdue, .active),
         (.paid, .active), // <-- happens when stripe webhook received before
         (.unpaid, .active):
      parent.subscriptionStatus = .paid
      parent.subscriptionId = subscriptionId
      parent.subscriptionStatusExpiration = now + .days(33)
      try await context.db.update(parent)

    case (let parentStatus, let stripeStatus):
      unexpected(
        "1146b93f",
        context,
        "admin: .\(parentStatus), stripe: .\(stripeStatus), subs: \(subscriptionId)"
      )
    }

    return .success
  }
}
