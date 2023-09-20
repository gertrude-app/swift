import Duet

final class KeystrokeLine: Codable {
  var id: Id
  var userDeviceId: UserDevice.Id
  var appName: String
  var line: String
  var filterSuspended: Bool
  var createdAt: Date
  var deletedAt: Date?

  var userDevice = Parent<UserDevice>.notLoaded

  init(
    id: Id = .init(),
    userDeviceId: UserDevice.Id,
    appName: String,
    line: String,
    filterSuspended: Bool = false,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.userDeviceId = userDeviceId
    self.appName = appName
    self.line = line
    self.filterSuspended = filterSuspended
    self.createdAt = createdAt
  }
}
