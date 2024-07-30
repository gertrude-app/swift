import DuetSQL

struct UserDevice: Codable, Sendable {
  var id: Id
  var userId: User.Id
  var deviceId: Device.Id
  var isAdmin: Bool?
  var appVersion: String
  var username: String
  var fullUsername: String
  var numericId: Int
  var createdAt = Date()
  var updatedAt = Date()

  init(
    id: Id = .init(),
    userId: User.Id,
    deviceId: Device.Id,
    isAdmin: Bool?,
    appVersion: String,
    username: String,
    fullUsername: String,
    numericId: Int
  ) {
    self.id = id
    self.userId = userId
    self.deviceId = deviceId
    self.appVersion = appVersion
    self.username = username
    self.fullUsername = fullUsername
    self.numericId = numericId
    self.isAdmin = isAdmin
  }
}

// extensions

extension UserDevice {
  func user() async throws -> User {
    try await Current.db.query(User.self)
      .where(.id == self.userId)
      .first()
  }

  func adminDevice() async throws -> Device {
    try await Current.db.query(Device.self)
      .where(.id == self.deviceId)
      .first()
  }
}

extension UserDevice {
  func isOnline() async -> Bool {
    await Current.connectedApps.isUserDeviceOnline(self.id)
  }
}
