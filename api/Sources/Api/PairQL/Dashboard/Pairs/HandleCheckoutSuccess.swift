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
    let session = try await Current.stripe.getCheckoutSession(input.stripeCheckoutSessionId)
    var admin = try await Current.db.find(session.adminId)
    let subscriptionId = try session.adminUserSubscriptionId
    let subscription = try await Current.stripe.getSubscription(subscriptionId.rawValue)
    switch (admin.subscriptionStatus, subscription.status) {

    case (.trialing, .active),
         (.trialExpiringSoon, .active),
         (.overdue, .active),
         (.paid, .active), // <-- happens when stripe webhook received before
         (.unpaid, .active):
      admin.subscriptionStatus = .paid
      admin.subscriptionId = subscriptionId
      admin.subscriptionStatusExpiration = Current.date().advanced(by: .days(33))
      try await admin.save()

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
