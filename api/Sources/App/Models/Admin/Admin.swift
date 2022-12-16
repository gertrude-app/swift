import DuetSQL
import Shared

final class Admin: Codable {
  var id: Id
  var email: EmailAddress
  var password: String
  var subscriptionId: SubscriptionId?
  var subscriptionStatus: SubscriptionStatus
  var createdAt = Date()
  var updatedAt = Date()
  var deletedAt: Date?

  var keychains = Children<Keychain>.notLoaded
  var users = Children<User>.notLoaded
  var notifications = Children<AdminNotification>.notLoaded
  var verifiedNotificationMethods = Children<AdminVerifiedNotificationMethod>.notLoaded
  var accountStatus: AdminAccountStatus { subscriptionStatus.accountStatus }

  init(
    id: Id = .init(),
    email: EmailAddress,
    password: String,
    subscriptionId: SubscriptionId? = nil,
    subscriptionStatus: SubscriptionStatus = .pendingEmailVerification
  ) {
    self.id = id
    self.email = email
    self.password = password
    self.subscriptionId = subscriptionId
    self.subscriptionStatus = subscriptionStatus
  }
}

// loaders

extension Admin {
  func users() async throws -> [User] {
    try await users.useLoaded(or: {
      try await Current.db.query(User.self)
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
    case emailVerified
    case signupCanceled
    case complimentary

    // below statuses map to Stripe statuses
    case incomplete
    case incompleteExpired
    case trialing
    case active
    case pastDue
    case canceled
    case unpaid

    var accountStatus: AdminAccountStatus {
      switch self {
      case .active, .trialing, .complimentary:
        return .active
      case .pastDue:
        return .needsAttention
      default:
        return .inactive
      }
    }
  }
}
