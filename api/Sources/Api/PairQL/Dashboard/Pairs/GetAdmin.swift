import Dependencies
import Foundation
import PairQL

struct GetAdmin: Pair {
  static let auth: ClientAuth = .admin

  struct Notification: PairNestable {
    var id: AdminNotification.Id
    var trigger: AdminNotification.Trigger
    var methodId: AdminVerifiedNotificationMethod.Id
  }

  struct VerifiedNotificationMethod: PairNestable {
    var id: AdminVerifiedNotificationMethod.Id
    var config: AdminVerifiedNotificationMethod.Config
  }

  enum SubscriptionStatus: PairNestable {
    case complimentary
    case trialing(daysLeft: Int)
    case paid
    case overdue
    case unpaid
  }

  struct Output: PairOutput {
    var id: Admin.Id
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
  static func resolve(in context: AdminContext) async throws -> Output {
    let admin = context.admin
    async let notifications = admin.notifications(in: context.db)
    async let methods = admin.verifiedNotificationMethods(in: context.db)
    async let hasAdminChild = try await admin.users(in: context.db)
      .concurrentMap { try await $0.computerUsers(in: context.db) }
      .flatMap(\.self)
      .contains { $0.isAdmin == true }

    return try await .init(
      id: admin.id,
      email: admin.email.rawValue,
      subscriptionStatus: .init(admin),
      notifications: notifications.map {
        .init(id: $0.id, trigger: $0.trigger, methodId: $0.methodId)
      },
      verifiedNotificationMethods: methods.map {
        .init(id: $0.id, config: $0.config)
      },
      hasAdminChild: hasAdminChild,
      monthlyPriceInDollars: Int(admin.monthlyPrice.rawValue / 100)
    )
  }
}

extension GetAdmin.SubscriptionStatus {
  init(_ admin: Admin) throws {
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
