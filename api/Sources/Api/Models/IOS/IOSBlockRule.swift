import DuetSQL
import GertieIOS

extension IOSApp {
  struct BlockRule: Codable, Sendable {
    var id: Id
    var deviceId: Device.Id?
    var vendorId: VendorId?
    var rule: GertieIOS.BlockRule
    var groupId: BlockGroup.Id?
    var comment: String?
    var createdAt = Date()
    var updatedAt = Date()

    init(
      id: Id = .init(),
      deviceId: Device.Id? = nil,
      vendorId: VendorId? = nil,
      rule: GertieIOS.BlockRule,
      groupId: BlockGroup.Id? = nil,
      comment: String? = nil,
    ) {
      self.id = id
      self.deviceId = deviceId
      self.vendorId = vendorId
      self.rule = rule
      self.groupId = groupId
      self.comment = comment
    }
  }
}

extension IOSApp.BlockRule {
  func device(in db: any DuetSQL.Client) async throws -> IOSApp.Device? {
    guard let deviceId = self.deviceId else {
      return nil
    }
    return try await IOSApp.Device.query()
      .where(.id == deviceId)
      .first(in: db)
  }
}
