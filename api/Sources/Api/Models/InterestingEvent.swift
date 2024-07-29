import Foundation

struct InterestingEvent: Codable, Sendable {
  var id: Id
  var eventId: String
  var kind: String
  var context: String
  var userDeviceId: UserDevice.Id?
  var adminId: Admin.Id?
  var detail: String?
  var createdAt = Date()

  init(
    id: Id = .init(),
    eventId: String,
    kind: String,
    context: String,
    userDeviceId: UserDevice.Id? = nil,
    adminId: Admin.Id? = nil,
    detail: String? = nil
  ) {
    self.id = id
    self.eventId = eventId
    self.kind = kind
    self.context = context
    self.userDeviceId = userDeviceId
    self.adminId = adminId
    self.detail = detail
  }
}
