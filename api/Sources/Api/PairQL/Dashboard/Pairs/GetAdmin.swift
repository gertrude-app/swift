import Dependencies
import Foundation
import PairQL

struct GetAdmin: Pair {
  static let auth: ClientAuth = .parent

  struct Notification: PairNestable {
    var id: Parent.Notification.Id
    var trigger: Parent.Notification.Trigger
    var methodId: Parent.NotificationMethod.Id
  }

  struct VerifiedNotificationMethod: PairNestable {
    var id: Parent.NotificationMethod.Id
    var config: Parent.NotificationMethod.Config
  }

  enum SubscriptionStatus: PairNestable {
    case complimentary
    case trialing(daysLeft: Int)
    case paid
    case overdue
    case unpaid
  }

  struct Output: PairOutput {
    var id: Parent.Id
    var email: String
    var subscriptionStatus: SubscriptionStatus
    var notifications: [Notification]
    var verifiedNotificationMethods: [VerifiedNotificationMethod]
    var hasAdminChild: Bool
    var monthlyPriceInDollars: Int
  }
}

// resolver

extension GetAdmin: NoInputResolver {
  static func resolve(in context: ParentContext) async throws -> Output {
    let parent = context.parent
    async let notifications = parent.notifications(in: context.db)
    async let methods = parent.verifiedNotificationMethods(in: context.db)
    async let hasAdminChild = try await parent.children(in: context.db)
      .concurrentMap { try await $0.computerUsers(in: context.db) }
      .flatMap(\.self)
      .contains { $0.isAdmin == true }

    return try await .init(
      id: parent.id,
      email: parent.email.rawValue,
      subscriptionStatus: .init(parent),
      notifications: notifications.map {
        .init(id: $0.id, trigger: $0.trigger, methodId: $0.methodId)
      },
      verifiedNotificationMethods: methods.map {
        .init(id: $0.id, config: $0.config)
      },
      hasAdminChild: hasAdminChild,
      monthlyPriceInDollars: Int(parent.monthlyPrice.rawValue / 100)
    )
  }
}

extension GetAdmin.SubscriptionStatus {
  init(_ admin: Parent) throws {
    @Dependency(\.date.now) var now
    switch admin.subscriptionStatus {
    case .complimentary:
      self = .complimentary
    case .trialing:
      let delta = now.distance(to: admin.subscriptionStatusExpiration)
      self = .trialing(daysLeft: Int(delta / 86400) + 7) // 7 days in "expiring soon"
    case .trialExpiringSoon:
      let delta = now.distance(to: admin.subscriptionStatusExpiration)
      self = .trialing(daysLeft: Int(delta / 86400))
    case .paid:
      self = .paid
    case .overdue:
      self = .overdue
    case .unpaid, .pendingAccountDeletion:
      self = .unpaid
    case .pendingEmailVerification:
      struct EmailNotVerified: Error {}
      throw EmailNotVerified() // should never happen
    }
  }
}
