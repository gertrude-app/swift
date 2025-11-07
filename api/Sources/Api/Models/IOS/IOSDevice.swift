import DuetSQL
import GertieIOS

extension IOSApp {
  struct Device: Codable, Sendable, Equatable {
    var id: Id
    var childId: Child.Id
    var vendorId: VendorId
    var deviceType: String
    var appVersion: String
    var iosVersion: String
    var webPolicy: String
    var createdAt = Date()
    var updatedAt = Date()

    init(
      id: Id? = nil,
      childId: Child.Id,
      vendorId: VendorId,
      deviceType: String,
      appVersion: String,
      iosVersion: String,
      webPolicy: String = "blockAll",
    ) {
      self.id = id ?? .init(get(dependency: \.uuid)())
      self.childId = childId
      self.vendorId = vendorId
      self.deviceType = deviceType
      self.appVersion = appVersion
      self.iosVersion = iosVersion
      self.webPolicy = webPolicy
    }
  }
}

// loaders

extension IOSApp.Device {
  func child(in db: any DuetSQL.Client) async throws -> Child {
    try await Child.query()
      .where(.id == self.childId)
      .first(in: db)
  }

  func blockGroups(in db: any DuetSQL.Client) async throws -> [IOSApp.BlockGroup] {
    let pivots = try await IOSApp.DeviceBlockGroup.query()
      .where(.deviceId == self.id)
      .all(in: db)
    return try await IOSApp.BlockGroup.query()
      .where(.id |=| pivots.map(\.blockGroupId))
      .all(in: db)
  }

  func blockRules(in db: any DuetSQL.Client) async throws -> [IOSApp.BlockRule] {
    try await IOSApp.BlockRule.query()
      .where(.deviceId == self.id)
      .all(in: db)
  }

  func webPolicyDomains(in db: any DuetSQL.Client) async throws -> [IOSApp.WebPolicyDomain] {
    try await IOSApp.WebPolicyDomain.query()
      .where(.deviceId == self.id)
      .all(in: db)
  }

  func webContentFilterPolicy(
    in db: any DuetSQL.Client,
  ) async throws -> WebContentFilterPolicy {
    let domains = try await self.webPolicyDomains(in: db).map(\.domain)
    switch self.webPolicy {
    case "allowAll":
      return .allowAll
    case "blockAdult":
      return .blockAdult
    case "blockAdultAnd":
      return .blockAdultAnd(Set(domains))
    case "blockAllExcept":
      return .blockAllExcept(Set(domains))
    case "blockAll":
      return .blockAll
    default:
      await with(dependency: \.slack)
        .error("unexpected web policy `\(self.webPolicy)` for ios device \(self.id)")
      return .blockAll
    }
  }
}
