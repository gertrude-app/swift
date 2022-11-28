import Duet

public final class Admin: Codable {
  public var id: Id
  public var email: EmailAddress
  public var password: String
  public var subscriptionId: SubscriptionId?
  public var subscriptionStatus: SubscriptionStatus
  public var createdAt = Date()
  public var updatedAt = Date()
  public var deletedAt: Date?

  // public var keychains = Children<Keychain>.notLoaded
  // public var users = Children<User>.notLoaded
  // public var notifications = Children<AdminNotification>.notLoaded
  // public var verifiedNotificationMethods = Children<AdminVerifiedNotificationMethod>.notLoaded
  // public var accountStatus: AccountStatus { subscriptionStatus.accountStatus }

  public init(
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

// extensions

public extension Admin {
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

    var accountStatus: AccountStatus {
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

public extension Admin {
  // TODO: this is shared, shouldn't be in here...
  enum AccountStatus: String, Codable, Equatable, CaseIterable {
    case active
    case needsAttention
    case inactive
  }
}
