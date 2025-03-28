import Duet
import GertieIOS

extension IOSApp {
  struct BlockRule: Codable, Sendable {
    var id: Id
    var deviceId: Device.Id?
    var vendorId: VendorId?
    var rule: GertieIOS.BlockRule
    var group: String?
    var comment: String?
    var createdAt = Date()
    var updatedAt = Date()

    init(
      id: Id = .init(),
      vendorId: VendorId? = nil,
      rule: GertieIOS.BlockRule,
      group: String? = nil,
      comment: String? = nil
    ) {
      self.id = id
      self.vendorId = vendorId
      self.rule = rule
      self.group = group
      self.comment = comment
    }
  }
}
