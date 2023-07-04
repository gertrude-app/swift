import Duet

final class Screenshot: Codable {
  var id: Id
  var deviceId: Device.Id
  var url: String
  var width: Int
  var height: Int
  var createdAt: Date
  var deletedAt: Date?

  var device = Parent<Device>.notLoaded

  init(
    id: Id = .init(),
    deviceId: Device.Id,
    url: String,
    width: Int,
    height: Int,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.url = url
    self.width = width
    self.height = height
    self.deviceId = deviceId
    self.createdAt = createdAt
  }
}
