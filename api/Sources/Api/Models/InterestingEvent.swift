import Foundation

final class InterestingEvent: Codable {
  var id: Id
  var eventId: String
  var kind: String
  var context: String
  var deviceId: Device.Id?
  var adminId: Admin.Id?
  var detail: String?
  var createdAt = Date()

  init(
    id: Id = .init(),
    eventId: String,
    kind: String,
    context: String,
    deviceId: Device.Id? = nil,
    adminId: Admin.Id? = nil,
    detail: String? = nil
  ) {
    self.id = id
    self.eventId = eventId
    self.kind = kind
    self.context = context
    self.deviceId = deviceId
    self.adminId = adminId
    self.detail = detail
  }
}
