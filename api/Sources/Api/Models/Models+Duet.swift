import DuetSQL
import Gertie
import Tagged

extension Model {
  @discardableResult
  func save() async throws -> Self {
    try await Current.db.update(self)
  }

  @discardableResult
  func create() async throws -> Self {
    try await Current.db.create(self)
  }

  @discardableResult
  func upsert() async throws -> Self {
    if (try? await Current.db.query(Self.self).byId(id).first()) == nil {
      return try await create()
    } else {
      return try await save()
    }
  }

  func delete() async throws {
    try await Current.db.query(Self.self).byId(id).delete()
  }

  static func find(_ id: Tagged<Self, UUID>) async throws -> Self {
    try await Current.db.query(Self.self).byId(id).first()
  }

  static func deleteAll() async throws {
    try await Current.db.query(Self.self).delete()
  }

  static func query() -> DuetQuery<Self> {
    Current.db.query(Self.self)
  }

  @discardableResult
  static func create(_ model: Self) async throws -> Self {
    try await Current.db.create(model)
  }

  @discardableResult
  static func create(_ models: [Self]) async throws -> [Self] {
    try await Current.db.create(models)
  }
}

extension Array where Element: Model {
  @discardableResult
  func create() async throws -> Self {
    try await Current.db.create(self)
  }

  @discardableResult
  func save() async throws -> Self {
    try await Current.db.update(self)
  }
}

extension RequestStatus: PostgresEnum {
  public var typeName: String { RequestTables.M5.requestStatusTypeName }
}

protocol HasCreatedAt {
  var createdAt: Date { get set }
}

protocol HasOptionalDeletedAt {
  var deletedAt: Date? { get set }
}

extension HasOptionalDeletedAt {
  var isDeleted: Bool {
    guard let deletedAt = deletedAt else { return false }
    return deletedAt < Current.date()
  }

  var notDeleted: Bool { !isDeleted }
}

extension KeystrokeLine: HasCreatedAt {}
extension Screenshot: HasCreatedAt {}
extension KeystrokeLine: HasOptionalDeletedAt {}
extension Screenshot: HasOptionalDeletedAt {}

extension Either where Left: HasCreatedAt, Right: HasCreatedAt {
  var createdAt: Date {
    switch self {
    case .left(let model):
      return model.createdAt
    case .right(let model):
      return model.createdAt
    }
  }
}

extension Admin: Duet.Identifiable {
  typealias Id = Tagged<Admin, UUID>
}

extension Admin {
  enum CodingKeys: String, CodingKey, CaseIterable {
    case id
    case email
    case password
    case subscriptionId
    case subscriptionStatus
    case subscriptionStatusExpiration
    case createdAt
    case updatedAt
  }
}

extension Admin.SubscriptionStatus: PostgresEnum {
  var typeName: String { Admin.M1.subscriptionStatusTypeName }
}

extension AdminNotification: Duet.Identifiable {
  typealias Id = Tagged<AdminNotification, UUID>
}

extension AdminNotification {
  enum CodingKeys: String, CodingKey, CaseIterable {
    case id
    case adminId
    case methodId
    case trigger
    case createdAt
  }
}

extension AdminNotification.Trigger: PostgresEnum {
  var typeName: String { AdminNotification.M1.triggerTypeName }
}

extension AdminToken: Duet.Identifiable {
  typealias Id = Tagged<AdminToken, UUID>
}

extension AdminToken {
  enum CodingKeys: String, CodingKey, CaseIterable {
    case id
    case adminId
    case value
    case createdAt
    case deletedAt
  }
}

extension AdminVerifiedNotificationMethod: Duet.Identifiable {
  typealias Id = Tagged<AdminVerifiedNotificationMethod, UUID>
}

extension AdminVerifiedNotificationMethod {
  enum CodingKeys: String, CodingKey, CaseIterable {
    case id
    case adminId
    case config
    case createdAt
  }
}

extension AppCategory: Duet.Identifiable {
  typealias Id = Tagged<AppCategory, UUID>
}

extension AppCategory {
  enum CodingKeys: String, CodingKey, CaseIterable {
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
  enum CodingKeys: String, CodingKey, CaseIterable {
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
  enum CodingKeys: String, CodingKey, CaseIterable {
    case id
    case adminId
    case customName
    case modelIdentifier
    case serialNumber
    case appReleaseChannel
    case filterVersion
    case createdAt
    case updatedAt
  }
}

extension UserDevice: Duet.Identifiable {
  typealias Id = Tagged<UserDevice, UUID>
}

extension UserDevice {
  enum CodingKeys: String, CodingKey, CaseIterable {
    case id
    case userId
    case deviceId
    case appVersion
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
  enum CodingKeys: String, CodingKey, CaseIterable {
    case id
    case categoryId
    case name
    case slug
    case selectable
    case description
    case createdAt
    case updatedAt
  }
}

extension Keychain: Duet.Identifiable {
  typealias Id = Tagged<Keychain, UUID>
}

extension Keychain {
  enum CodingKeys: String, CodingKey, CaseIterable {
    case id
    case authorId
    case name
    case description
    case isPublic
    case createdAt
    case updatedAt
    case deletedAt
  }
}

extension Key: Duet.Identifiable {
  typealias Id = Tagged<Key, UUID>
}

extension Key {
  enum CodingKeys: String, CodingKey, CaseIterable {
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
  enum CodingKeys: String, CodingKey, CaseIterable {
    case id
    case userDeviceId
    case appName
    case line
    case filterSuspended
    case createdAt
    case deletedAt
  }
}

extension NetworkDecisionVerdict: PostgresEnum {
  public var typeName: String { LegacyNetworkDecision.M5.verdictTypeName }
}

extension NetworkDecisionReason: PostgresEnum {
  public var typeName: String { LegacyNetworkDecision.M5.reasonTypeName }
}

extension Release: Duet.Identifiable {
  typealias Id = Tagged<Release, UUID>
}

extension Release {
  enum CodingKeys: String, CodingKey, CaseIterable {
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

extension ReleaseChannel: PostgresEnum {
  public var typeName: String { Release.M7.channelTypeName }
}

extension StripeEvent: Duet.Identifiable {
  typealias Id = Tagged<StripeEvent, UUID>
}

extension StripeEvent {
  enum CodingKeys: String, CodingKey, CaseIterable {
    case id
    case json
    case createdAt
  }
}

extension Screenshot: Duet.Identifiable {
  typealias Id = Tagged<Screenshot, UUID>
}

extension Screenshot {
  enum CodingKeys: String, CodingKey, CaseIterable {
    case id
    case userDeviceId
    case url
    case width
    case height
    case filterSuspended
    case createdAt
    case deletedAt
  }
}

extension SuspendFilterRequest: Duet.Identifiable {
  typealias Id = Tagged<SuspendFilterRequest, UUID>
}

extension SuspendFilterRequest {
  enum CodingKeys: String, CodingKey, CaseIterable {
    case id
    case userDeviceId
    case status
    case scope
    case duration
    case requestComment
    case responseComment
    case createdAt
    case updatedAt
  }
}

extension UnlockRequest: Duet.Identifiable {
  typealias Id = Tagged<UnlockRequest, UUID>
}

extension UnlockRequest {
  enum CodingKeys: String, CodingKey, CaseIterable {
    case id
    case userDeviceId
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
  enum CodingKeys: String, CodingKey, CaseIterable {
    case id
    case adminId
    case name
    case keyloggingEnabled
    case screenshotsEnabled
    case screenshotsResolution
    case screenshotsFrequency
    case showSuspensionActivity
    case createdAt
    case updatedAt
    case deletedAt
  }
}

extension UserKeychain: Duet.Identifiable {
  typealias Id = Tagged<UserKeychain, UUID>
}

extension UserKeychain {
  enum CodingKeys: String, CodingKey, CaseIterable {
    case id
    case userId
    case keychainId
    case createdAt
  }
}

extension UserToken: Duet.Identifiable {
  typealias Id = Tagged<UserToken, UUID>
}

extension UserToken {
  enum CodingKeys: String, CodingKey, CaseIterable {
    case id
    case userId
    case userDeviceId
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
  enum CodingKeys: String, CodingKey, CaseIterable {
    case id
    case eventId
    case kind
    case context
    case userDeviceId
    case adminId
    case detail
    case createdAt
  }
}

extension DeletedEntity: Duet.Identifiable {
  typealias Id = Tagged<DeletedEntity, UUID>
}

extension DeletedEntity {
  enum CodingKeys: String, CodingKey, CaseIterable {
    case id
    case type
    case reason
    case data
    case createdAt
  }
}
