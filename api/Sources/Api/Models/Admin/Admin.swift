import DuetSQL
import Gertie

final class Admin: Codable {
  var id: Id
  var email: EmailAddress
  var password: String
  var subscriptionId: SubscriptionId?
  var subscriptionStatus: SubscriptionStatus
  var subscriptionStatusExpiration: Date
  var gclid: String?
  var createdAt = Date()
  var updatedAt = Date()
  var deletedAt: Date?

  var devices = Children<Device>.notLoaded
  var keychains = Children<Keychain>.notLoaded
  var users = Children<User>.notLoaded
  var notifications = Children<AdminNotification>.notLoaded
  var verifiedNotificationMethods = Children<AdminVerifiedNotificationMethod>.notLoaded
  var accountStatus: AdminAccountStatus { self.subscriptionStatus.accountStatus }

  init(
    id: Id = .init(),
    email: EmailAddress,
    password: String,
    subscriptionStatus: SubscriptionStatus = .pendingEmailVerification,
    subscriptionStatusExpiration: Date = Date().advanced(by: .days(7)),
    subscriptionId: SubscriptionId? = nil,
    gclid: String? = nil
  ) {
    self.id = id
    self.email = email
    self.password = password
    self.subscriptionId = subscriptionId
    self.subscriptionStatus = subscriptionStatus
    self.subscriptionStatusExpiration = subscriptionStatusExpiration
    self.gclid = gclid
  }
}

// loaders

extension Admin {
  func keychains() async throws -> [Keychain] {
    try await self.keychains.useLoaded(or: {
      try await Current.db.query(Keychain.self)
        .where(.authorId == id)
        .all()
    })
  }

  func keychain(_ keychainId: Keychain.Id) async throws -> Keychain {
    try await Current.db.query(Keychain.self)
      .where(.authorId == self.id)
      .where(.id == keychainId)
      .first()
  }

  func users() async throws -> [User] {
    try await self.users.useLoaded(or: {
      try await Current.db.query(User.self)
        .where(.adminId == id)
        .all()
    })
  }

  func devices() async throws -> [Device] {
    try await self.devices.useLoaded(or: {
      try await Current.db.query(Device.self)
        .where(.adminId == id)
        .all()
    })
  }

  func notifications() async throws -> [AdminNotification] {
    try await self.notifications.useLoaded(or: {
      try await Current.db.query(AdminNotification.self)
        .where(.adminId == id)
        .all()
    })
  }

  func verifiedNotificationMethods() async throws -> [AdminVerifiedNotificationMethod] {
    try await self.verifiedNotificationMethods.useLoaded(or: {
      try await Current.db.query(AdminVerifiedNotificationMethod.self)
        .where(.adminId == id)
        .all()
    })
  }
}

// extensions

extension Admin {
  typealias SubscriptionId = Tagged<Admin, String>

  enum SubscriptionStatus: String, Codable, Equatable, CaseIterable {
    case pendingEmailVerification
    case trialing
    case trialExpiringSoon
    case overdue
    case paid
    case unpaid
    case pendingAccountDeletion
    case complimentary

    var accountStatus: AdminAccountStatus {
      switch self {
      case .paid, .trialing, .trialExpiringSoon, .complimentary:
        return .active
      case .overdue:
        return .needsAttention
      case .pendingEmailVerification, .unpaid, .pendingAccountDeletion:
        return .inactive
      }
    }
  }
}
