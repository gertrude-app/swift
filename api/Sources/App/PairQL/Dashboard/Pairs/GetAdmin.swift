import Foundation
import TypescriptPairQL

struct GetAdmin: TypescriptPair {
  static var auth: ClientAuth = .admin

  struct Notification: TypescriptNestable {
    let id: UUID
    let trigger: AdminNotification.Trigger
    let methodId: UUID
  }

  struct VerifiedSlackMethod: TypescriptNestable {
    let id: UUID
    let channelId: String
    let channelName: String
    let token: String
  }

  struct VerifiedEmailMethod: TypescriptNestable {
    let id: UUID
    let email: EmailAddress
  }

  struct VerifiedTextMethod: TypescriptNestable {
    let id: UUID
    let phoneNumber: String
  }

  struct Output: TypescriptPairOutput {
    let id: UUID
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
      id: admin.id.rawValue,
      email: admin.email.rawValue,
      notifications: notifications.map {
        .init(id: $0.id.rawValue, trigger: $0.trigger, methodId: $0.methodId.rawValue)
      },
      verifiedNotificationMethods: methods.map { verifiedMethod in
        switch verifiedMethod.method {
        case .email(let email):
          return .a(.init(id: verifiedMethod.id.rawValue, email: .init(email)))
        case .slack(let channelId, let channelName, let token):
          return .b(.init(
            id: verifiedMethod.id.rawValue,
            channelId: channelId,
            channelName: channelName,
            token: token
          ))
        case .text(let phoneNumber):
          return .c(.init(id: verifiedMethod.id.rawValue, phoneNumber: phoneNumber))
        }
      }
    )
  }
}

// extensions

extension Admin.SubscriptionStatus: NamedType {
  static var __typeName: String { "AdminSubscriptionStatus" }
}

extension AdminNotification.Trigger: NamedType {
  static var __typeName: String { "AdminNotificationTrigger" }
}
