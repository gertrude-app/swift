import DuetSQL
import Gertie

struct Admin: Codable, Sendable {
  var id: Id
  var email: EmailAddress
  var password: String
  var subscriptionId: SubscriptionId?
  var subscriptionStatus: SubscriptionStatus
  var subscriptionStatusExpiration: Date
  var gclid: String?
  var abTestVariant: String?
  var createdAt = Date()
  var updatedAt = Date()

  var accountStatus: AdminAccountStatus {
    self.subscriptionStatus.accountStatus
  }

  var isPendingEmailVerification: Bool {
    self.subscriptionStatus == .pendingEmailVerification
  }

  init(
    id: Id = .init(),
    email: EmailAddress,
    password: String,
    subscriptionStatus: SubscriptionStatus = .pendingEmailVerification,
    subscriptionStatusExpiration: Date = Date().advanced(by: .days(7)),
    subscriptionId: SubscriptionId? = nil,
    gclid: String? = nil,
    abTestVariant: String? = nil
  ) {
    self.id = id
    self.email = email
    self.password = password
    self.subscriptionId = subscriptionId
    self.subscriptionStatus = subscriptionStatus
    self.subscriptionStatusExpiration = subscriptionStatusExpiration
    self.gclid = gclid
    self.abTestVariant = abTestVariant
  }
}

// loaders

extension Admin {
  func keychains(in db: any DuetSQL.Client) async throws -> [Keychain] {
    try await Keychain.query()
      .where(.authorId == self.id)
      .all(in: db)
  }

  func keychain(_ keychainId: Keychain.Id, in db: any DuetSQL.Client) async throws -> Keychain {
    try await Keychain.query()
      .where(.authorId == self.id)
      .where(.id == keychainId)
      .first(in: db)
  }

  func users(in db: any DuetSQL.Client) async throws -> [User] {
    try await User.query()
      .where(.adminId == self.id)
      .all(in: db)
  }

  func devices(in db: any DuetSQL.Client) async throws -> [Device] {
    try await Device.query()
      .where(.adminId == self.id)
      .all(in: db)
  }

  func notifications(in db: any DuetSQL.Client) async throws -> [AdminNotification] {
    try await AdminNotification.query()
      .where(.adminId == self.id)
      .all(in: db)
  }

  func verifiedNotificationMethods(
    in db: any DuetSQL.Client
  ) async throws -> [AdminVerifiedNotificationMethod] {
    try await AdminVerifiedNotificationMethod.query()
      .where(.adminId == self.id)
      .all(in: db)
  }
}

// extensions

extension Admin {
  typealias SubscriptionId = Tagged<Admin, String>

  enum SubscriptionStatus: String, Codable, Equatable, CaseIterable, Sendable {
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
