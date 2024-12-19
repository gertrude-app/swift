import Duet
import GertieIOS

struct IOSBlockRule: Codable, Sendable {
  var id: Id
  var vendorId: VendorId?
  var rule: BlockRule
  var group: String?
  var comment: String?
  var createdAt = Date()
  var updatedAt = Date()

  init(
    id: Id = .init(),
    vendorId: VendorId? = nil,
    rule: BlockRule,
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
