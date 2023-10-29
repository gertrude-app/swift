import Foundation
import PairQL

struct GetAdmin: Pair {
  static var auth: ClientAuth = .admin

  struct Notification: PairNestable {
    let id: AdminNotification.Id
    let trigger: AdminNotification.Trigger
    let methodId: AdminVerifiedNotificationMethod.Id
  }

  struct VerifiedNotificationMethod: PairNestable {
    let id: AdminVerifiedNotificationMethod.Id
    let config: AdminVerifiedNotificationMethod.Config
  }

  enum SubscriptionStatus: PairNestable {
    case complimentary
    case trialing(daysLeft: Int)
    case paid
    case overdue
    case unpaid
  }

  struct Output: PairOutput {
    let id: Admin.Id
    let email: String
    let subscriptionStatus: SubscriptionStatus
    let notifications: [Notification]
    let verifiedNotificationMethods: [VerifiedNotificationMethod]
  }
}

// resolver

extension GetAdmin: NoInputResolver {
  static func resolve(in context: AdminContext) async throws -> Output {
    let admin = context.admin
    let notifications = try await admin.notifications()
    let methods = try await admin.verifiedNotificationMethods()
    return .init(
      id: admin.id,
      email: admin.email.rawValue,
      subscriptionStatus: try .init(admin),
      notifications: notifications.map {
        .init(id: $0.id, trigger: $0.trigger, methodId: $0.methodId)
      },
      verifiedNotificationMethods: methods.map {
        .init(id: $0.id, config: $0.config)
      }
    )
  }
}

extension GetAdmin.SubscriptionStatus {
  init(_ admin: Admin) throws {
    switch admin.subscriptionStatus {
    case .complimentary:
      self = .complimentary
    case .trialing:
      let delta = Current.date().distance(to: admin.subscriptionStatusExpiration)
      self = .trialing(daysLeft: Int(delta / 86400) + 7) // 7 days in "expiring soon"
    case .trialExpiringSoon:
      let delta = Current.date().distance(to: admin.subscriptionStatusExpiration)
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
