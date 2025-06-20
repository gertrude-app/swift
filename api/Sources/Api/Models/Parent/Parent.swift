import DuetSQL
import Gertie
import TaggedMoney

struct Parent: Codable, Sendable {
  var id: Id
  var email: EmailAddress
  var password: String
  var subscriptionId: SubscriptionId?
  var subscriptionStatus: SubscriptionStatus
  var subscriptionStatusExpiration: Date
  var monthlyPrice: Cents<Int>
  var trialPeriodDays: Int
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
    monthlyPrice: Cents<Int> = .init(1500),
    trialPeriodDays: Int = 21,
    gclid: String? = nil,
    abTestVariant: String? = nil
  ) {
    self.id = id
    self.email = email
    self.password = password
    self.subscriptionId = subscriptionId
    self.subscriptionStatus = subscriptionStatus
    self.subscriptionStatusExpiration = subscriptionStatusExpiration
    self.monthlyPrice = monthlyPrice
    self.trialPeriodDays = trialPeriodDays
    self.gclid = gclid
    self.abTestVariant = abTestVariant
  }
}

// extensions

extension Parent {
  var stripePriceId: String {
    switch self.monthlyPrice.rawValue {
    case 1500: // new vinci-price, Feb 2025
      "price_1QooP1GKRdhETuKAcVawow7B"
    case 1000: // GHC conf special
      "price_1RJbTrGKRdhETuKAkI5OO1NB"
    case 100: // test price decrease
      "price_1Rc5cYGKRdhETuKApY0VOxR1"
    default: // legacy price
      "price_1M9xZYGKRdhETuKA22aYJ4fI"
    }
  }
}

// loaders

extension Parent {
  func keychains(in db: any DuetSQL.Client) async throws -> [Keychain] {
    try await Keychain.query()
      .where(.parentId == self.id)
      .all(in: db)
  }

  func keychain(_ keychainId: Keychain.Id, in db: any DuetSQL.Client) async throws -> Keychain {
    try await Keychain.query()
      .where(.parentId == self.id)
      .where(.id == keychainId)
      .first(in: db)
  }

  func children(in db: any DuetSQL.Client) async throws -> [Child] {
    try await Child.query()
      .where(.parentId == self.id)
      .all(in: db)
  }

  func computers(in db: any DuetSQL.Client) async throws -> [Computer] {
    try await Computer.query()
      .where(.parentId == self.id)
      .all(in: db)
  }

  func notifications(in db: any DuetSQL.Client) async throws -> [Parent.Notification] {
    try await Parent.Notification.query()
      .where(.parentId == self.id)
      .all(in: db)
  }

  func verifiedNotificationMethods(
    in db: any DuetSQL.Client
  ) async throws -> [Parent.NotificationMethod] {
    try await Parent.NotificationMethod.query()
      .where(.parentId == self.id)
      .all(in: db)
  }
}

// extensions

extension Parent {
  typealias SubscriptionId = Tagged<Parent, String>

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
        .active
      case .overdue:
        .needsAttention
      case .pendingEmailVerification, .unpaid, .pendingAccountDeletion:
        .inactive
      }
    }
  }
}
