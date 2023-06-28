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

  struct Output: PairOutput {
    let id: Admin.Id
    let email: String
    let subscriptionStatus: Admin.SubscriptionStatus
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
      subscriptionStatus: admin.subscriptionStatus,
      notifications: notifications.map {
        .init(id: $0.id, trigger: $0.trigger, methodId: $0.methodId)
      },
      verifiedNotificationMethods: methods.map {
        .init(id: $0.id, config: $0.config)
      }
    )
  }
}
