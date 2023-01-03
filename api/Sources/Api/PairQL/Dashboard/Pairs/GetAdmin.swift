import Foundation
import TypescriptPairQL

struct GetAdmin: TypescriptPair {
  static var auth: ClientAuth = .admin

  struct Notification: TypescriptNestable {
    let id: AdminNotification.Id
    let trigger: AdminNotification.Trigger
    let methodId: AdminVerifiedNotificationMethod.Id
  }

  struct VerifiedSlackMethod: TypescriptNestable {
    let id: AdminVerifiedNotificationMethod.Id
    let channelId: String
    let channelName: String
    let token: String
  }

  struct VerifiedEmailMethod: TypescriptNestable {
    let id: AdminVerifiedNotificationMethod.Id
    let email: String
  }

  struct VerifiedTextMethod: TypescriptNestable {
    let id: AdminVerifiedNotificationMethod.Id
    let phoneNumber: String
  }

  struct Output: TypescriptPairOutput {
    let id: Admin.Id
    let email: String
    let notifications: [Notification]
    let verifiedNotificationMethods: [Union3<
      VerifiedEmailMethod,
      VerifiedSlackMethod,
      VerifiedTextMethod
    >]
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
      notifications: notifications.map {
        .init(id: $0.id, trigger: $0.trigger, methodId: $0.methodId)
      },
      verifiedNotificationMethods: methods.map { verifiedMethod in
        switch verifiedMethod.method {
        case .email(let email):
          return .t1(.init(id: verifiedMethod.id, email: email))
        case .slack(let channelId, let channelName, let token):
          return .t2(.init(
            id: verifiedMethod.id,
            channelId: channelId,
            channelName: channelName,
            token: token
          ))
        case .text(let phoneNumber):
          return .t3(.init(id: verifiedMethod.id, phoneNumber: phoneNumber))
        }
      }
    )
  }
}

// extensions

extension Admin.SubscriptionStatus: NamedType {
  static var __typeName: String { "AdminSubscriptionStatus" }
}

extension AdminNotification.Trigger: GlobalType {
  static var __typeName: String { "AdminNotificationTrigger" }
}
