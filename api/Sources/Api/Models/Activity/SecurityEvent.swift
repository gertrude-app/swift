import Duet

struct SecurityEvent: Codable, Sendable {
  var id: Id
  var parentId: Admin.Id
  var computerUserId: ComputerUser.Id?
  var event: String
  var detail: String?
  var ipAddress: String?
  var createdAt: Date

  init(
    id: Id = .init(),
    parentId: Admin.Id,
    computerUserId: ComputerUser.Id? = nil,
    event: String,
    detail: String? = nil,
    ipAddress: String? = nil,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.parentId = parentId
    self.computerUserId = computerUserId
    self.event = event
    self.detail = detail
    self.ipAddress = ipAddress
    self.createdAt = createdAt
  }
}
