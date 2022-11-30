import Duet

final class KeystrokeLine: Codable {
  var id: Id
  var deviceId: Device.Id
  var appName: String
  var line: String
  var createdAt: Date
  var deletedAt: Date?

  var device = Parent<Device>.notLoaded

  init(
    id: Id = .init(),
    deviceId: Device.Id,
    appName: String,
    line: String,
    createdAt: Date
  ) {
    self.id = id
    self.deviceId = deviceId
    self.appName = appName
    self.line = line
    self.createdAt = createdAt
  }
}
