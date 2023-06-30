import Foundation

final class UnexpectedError: Codable {
  var id: Id
  var errorId: String
  var context: String
  var deviceId: Device.Id?
  var adminId: Admin.Id?
  var detail: String?
  var createdAt = Date()

  init(
    id: Id = .init(),
    errorId: String,
    context: String,
    deviceId: Device.Id? = nil,
    adminId: Admin.Id? = nil,
    detail: String? = nil
  ) {
    self.id = id
    self.errorId = errorId
    self.context = context
    self.deviceId = deviceId
    self.adminId = adminId
    self.detail = detail
  }
}
