import Duet

struct DeviceApp: Codable, Sendable {
  var id: Id
  var deviceId: Device.Id
  var appId: IdentifiedApp.Id
  var createdAt = Date()
  var updatedAt = Date()

  init(
    id: Id = .init(),
    deviceId: Device.Id,
    appId: IdentifiedApp.Id
  ) {
    self.id = id
    self.deviceId = deviceId
    self.appId = appId
  }
}
