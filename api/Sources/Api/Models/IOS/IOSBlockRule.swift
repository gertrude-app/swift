import Duet
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
      vendorId: VendorId? = nil,
      rule: GertieIOS.BlockRule,
      groupId: BlockGroup.Id? = nil,
      comment: String? = nil
    ) {
      self.id = id
      self.vendorId = vendorId
      self.rule = rule
      self.groupId = groupId
      self.comment = comment
    }
  }
}
