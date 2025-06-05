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

extension DashAnnouncement: Duet.Identifiable {
  typealias Id = Tagged<DashAnnouncement, UUID>
}

extension DashAnnouncement {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case parentId
    case icon
    case html
    case learnMoreUrl
    case createdAt
    case deletedAt
  }
}

extension IOSApp.SuspendFilterRequest {
  typealias Id = Tagged<IOSApp.SuspendFilterRequest, UUID>
}

extension IOSApp.SuspendFilterRequest {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case deviceId
    case status
    case duration
    case requestComment
    case responseComment
    case createdAt
    case updatedAt
  }
}

extension IOSApp.Token {
  typealias Id = Tagged<IOSApp.Token, UUID>
  typealias Value = Tagged<(IOSApp.Token, value: ()), UUID>
}

extension IOSApp.Token {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case deviceId
    case value
    case createdAt
    case updatedAt
  }
}

extension IOSApp.Device: Duet.Identifiable {
  typealias Id = Tagged<IOSApp.Device, UUID>
  typealias VendorId = Tagged<(t: IOSApp.Device, vendorId: ()), UUID>
}

extension IOSApp.Device {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case childId
    case vendorId
    case deviceType
    case appVersion
    case iosVersion
    case createdAt
    case updatedAt
  }
}

extension IOSApp.BlockRule: Duet.Identifiable {
  typealias Id = Tagged<IOSApp.BlockRule, UUID>
  typealias VendorId = Tagged<(t: IOSApp.BlockRule, vendorId: ()), UUID>
}

extension IOSApp.BlockRule {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case deviceId
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

extension Parent: Duet.Identifiable {
  typealias Id = Tagged<Parent, UUID>
}

extension Parent {
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

extension Parent.SubscriptionStatus: PostgresEnum {
  var typeName: String { "enum_parent_subscription_status" }
}

extension Parent.Notification: Duet.Identifiable {
  typealias Id = Tagged<Parent.Notification, UUID>
}

extension Parent.Notification {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case parentId
    case methodId
    case trigger
    case createdAt
  }
}

extension Parent.Notification.Trigger: PostgresEnum {
  var typeName: String { "enum_parent_notification_trigger" }
}

extension Parent.DashToken: Duet.Identifiable {
  typealias Id = Tagged<Parent.DashToken, UUID>
}

extension Parent.DashToken {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case parentId
    case value
    case createdAt
    case deletedAt
  }
}

extension Parent.NotificationMethod: Duet.Identifiable {
  typealias Id = Tagged<Parent.NotificationMethod, UUID>
}

extension Parent.NotificationMethod {
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

extension Computer: Duet.Identifiable {
  typealias Id = Tagged<Computer, UUID>
}

extension Computer {
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

extension ComputerUser: Duet.Identifiable {
  typealias Id = Tagged<ComputerUser, UUID>
}

extension ComputerUser {
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
    case iosDeviceId
    case url
    case width
    case height
    case filterSuspended
    case flagged
    case createdAt
    case deletedAt
  }
}

extension MacApp.SuspendFilterRequest: Duet.Identifiable {
  typealias Id = Tagged<MacApp.SuspendFilterRequest, UUID>
}

extension MacApp.SuspendFilterRequest {
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

extension Child: Duet.Identifiable {
  typealias Id = Tagged<Child, UUID>
}

extension Child {
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

extension ChildKeychain: Duet.Identifiable {
  typealias Id = Tagged<ChildKeychain, UUID>
}

extension ChildKeychain {
  enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    case id
    case childId
    case keychainId
    case schedule
    case createdAt
  }
}

extension MacAppToken: Duet.Identifiable {
  typealias Id = Tagged<MacAppToken, UUID>
}

extension MacAppToken {
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
