import Duet

struct SecurityEvent: Codable, Sendable {
  var id: Id
  var adminId: Admin.Id
  var userDeviceId: UserDevice.Id?
  var event: String
  var detail: String?
  var ipAddress: String?
  var createdAt: Date

  init(
    id: Id = .init(),
    adminId: Admin.Id,
    userDeviceId: UserDevice.Id? = nil,
    event: String,
    detail: String? = nil,
    ipAddress: String? = nil,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.adminId = adminId
    self.userDeviceId = userDeviceId
    self.event = event
    self.detail = detail
    self.ipAddress = ipAddress
    self.createdAt = createdAt
  }
}
