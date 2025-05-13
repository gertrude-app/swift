import Dependencies
import DuetSQL
import Gertie
import Tagged

extension RequestStatus: @retroactive PostgresEnum {
  public var typeName: String { "enum_shared_request_status" }
}

protocol HasCreatedAt {
  var createdAt: Date { get set }
}

protocol HasOptionalDeletedAt {
  var deletedAt: Date? { get set }
}

extension HasOptionalDeletedAt {
  var isDeleted: Bool {
    guard let deletedAt else { return false }
    @Dependency(\.date.now) var now
    return deletedAt < now
  }

  var notDeleted: Bool { !self.isDeleted }
}

extension KeystrokeLine: HasCreatedAt {}
extension Screenshot: HasCreatedAt {}
extension KeystrokeLine: HasOptionalDeletedAt {}
extension Screenshot: HasOptionalDeletedAt {}

extension Either where Left: HasCreatedAt, Right: HasCreatedAt {
  var createdAt: Date {
    switch self {
    case .left(let model):
      model.createdAt
    case .right(let model):
      model.createdAt
    }
  }
}

extension IOSBlockRule: Duet.Identifiable {
  typealias Id = Tagged<IOSBlockRule, UUID>
  typealias VendorId = Tagged<(t: IOSBlockRule, vendorId: ()), UUID>
}

extension IOSBlockRule {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case vendorId
    case rule
    case group
    case comment
    case createdAt
    case updatedAt
  }
}

extension UserBlockedApp: Duet.Identifiable {
  typealias Id = Tagged<UserBlockedApp, UUID>
}

extension UserBlockedApp {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case identifier
    case childId
    case schedule
    case createdAt
    case updatedAt
  }
}

extension Admin: Duet.Identifiable {
  typealias Id = Tagged<Admin, UUID>
}

extension Admin {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case email
    case password
    case subscriptionId
    case subscriptionStatus
    case subscriptionStatusExpiration
    case gclid
    case abTestVariant
    case monthlyPrice
    case trialPeriodDays
    case createdAt
    case updatedAt
  }
}

extension Admin.SubscriptionStatus: PostgresEnum {
  var typeName: String { "enum_parent_subscription_status" }
}

extension AdminNotification: Duet.Identifiable {
  typealias Id = Tagged<AdminNotification, UUID>
}

extension AdminNotification {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case parentId
    case methodId
    case trigger
    case createdAt
  }
}

extension AdminNotification.Trigger: PostgresEnum {
  var typeName: String { "enum_parent_notification_trigger" }
}

extension AdminToken: Duet.Identifiable {
  typealias Id = Tagged<AdminToken, UUID>
}

extension AdminToken {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case parentId
    case value
    case createdAt
    case deletedAt
  }
}

extension AdminVerifiedNotificationMethod: Duet.Identifiable {
  typealias Id = Tagged<AdminVerifiedNotificationMethod, UUID>
}

extension AdminVerifiedNotificationMethod {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case parentId
    case config
    case createdAt
  }
}

extension AppCategory: Duet.Identifiable {
  typealias Id = Tagged<AppCategory, UUID>
}

extension AppCategory {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case name
    case slug
    case description
    case createdAt
    case updatedAt
  }
}

extension AppBundleId: Duet.Identifiable {
  typealias Id = Tagged<AppBundleId, UUID>
}

extension AppBundleId {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case bundleId
    case identifiedAppId
    case createdAt
    case updatedAt
  }
}

extension Device: Duet.Identifiable {
  typealias Id = Tagged<Device, UUID>
}

extension Device {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case parentId
    case customName
    case modelIdentifier
    case serialNumber
    case appReleaseChannel
    case filterVersion
    case osVersion
    case createdAt
    case updatedAt
  }
}

extension UserDevice: Duet.Identifiable {
  typealias Id = Tagged<UserDevice, UUID>
}

extension UserDevice {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case childId
    case computerId
    case appVersion
    case isAdmin
    case username
    case fullUsername
    case numericId
    case createdAt
    case updatedAt
  }
}

extension IdentifiedApp: Duet.Identifiable {
  typealias Id = Tagged<IdentifiedApp, UUID>
}

extension IdentifiedApp {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case categoryId
    case name
    case slug
    case launchable
    case createdAt
    case updatedAt
  }
}

extension Keychain: Duet.Identifiable {
  typealias Id = Tagged<Keychain, UUID>
}

extension Keychain {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case parentId
    case name
    case description
    case warning
    case isPublic
    case createdAt
    case updatedAt
  }
}

extension Key: Duet.Identifiable {
  typealias Id = Tagged<Key, UUID>
}

extension Key {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case keychainId
    case key
    case comment
    case createdAt
    case updatedAt
    case deletedAt
  }
}

extension KeystrokeLine: Duet.Identifiable {
  typealias Id = Tagged<KeystrokeLine, UUID>
}

extension KeystrokeLine {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case computerUserId
    case appName
    case line
    case filterSuspended
    case flagged
    case createdAt
    case deletedAt
  }
}

extension Release: Duet.Identifiable {
  typealias Id = Tagged<Release, UUID>
}

extension Release {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case semver
    case channel
    case signature
    case length
    case revision
    case requirementPace
    case notes
    case createdAt
    case updatedAt
  }
}

extension ReleaseChannel: @retroactive PostgresEnum {
  public var typeName: String { "enum_release_channels" }
}

extension StripeEvent: Duet.Identifiable {
  typealias Id = Tagged<StripeEvent, UUID>
}

extension StripeEvent {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case json
    case createdAt
  }
}

extension Screenshot: Duet.Identifiable {
  typealias Id = Tagged<Screenshot, UUID>
}

extension Screenshot {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case computerUserId
    case url
    case width
    case height
    case filterSuspended
    case flagged
    case createdAt
    case deletedAt
  }
}

extension SuspendFilterRequest: Duet.Identifiable {
  typealias Id = Tagged<SuspendFilterRequest, UUID>
}

extension SuspendFilterRequest {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case computerUserId
    case status
    case scope
    case duration
    case requestComment
    case responseComment
    case extraMonitoring
    case createdAt
    case updatedAt
  }
}

extension UnlockRequest: Duet.Identifiable {
  typealias Id = Tagged<UnlockRequest, UUID>
}

extension UnlockRequest {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case computerUserId
    case status
    case requestComment
    case responseComment
    case appBundleId
    case url
    case hostname
    case ipAddress
    case createdAt
    case updatedAt
  }
}

extension User: Duet.Identifiable {
  typealias Id = Tagged<User, UUID>
}

extension User {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case parentId
    case name
    case keyloggingEnabled
    case screenshotsEnabled
    case screenshotsResolution
    case screenshotsFrequency
    case showSuspensionActivity
    case downtime
    case createdAt
    case updatedAt
  }
}

extension UserKeychain: Duet.Identifiable {
  typealias Id = Tagged<UserKeychain, UUID>
}

extension UserKeychain {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case childId
    case keychainId
    case schedule
    case createdAt
  }
}

extension UserToken: Duet.Identifiable {
  typealias Id = Tagged<UserToken, UUID>
}

extension UserToken {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case childId
    case computerUserId
    case value
    case createdAt
    case updatedAt
    case deletedAt
  }
}

extension InterestingEvent: Duet.Identifiable {
  typealias Id = Tagged<InterestingEvent, UUID>
}

extension InterestingEvent {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case eventId
    case kind
    case context
    case computerUserId
    case parentId
    case detail
    case createdAt
  }
}

extension DeletedEntity: Duet.Identifiable {
  typealias Id = Tagged<DeletedEntity, UUID>
}

extension DeletedEntity {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case type
    case reason
    case data
    case createdAt
  }
}

extension Browser: Duet.Identifiable {
  typealias Id = Tagged<Browser, UUID>
}

extension Browser {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case match
    case createdAt
  }
}

extension UnidentifiedApp: Duet.Identifiable {
  typealias Id = Tagged<UnidentifiedApp, UUID>
}

extension UnidentifiedApp {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case bundleId
    case bundleName
    case localizedName
    case launchable
    case count
    case createdAt
  }
}

extension SecurityEvent: Duet.Identifiable {
  typealias Id = Tagged<SecurityEvent, UUID>
}

extension SecurityEvent {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case parentId
    case computerUserId
    case event
    case detail
    case ipAddress
    case createdAt
  }
}
