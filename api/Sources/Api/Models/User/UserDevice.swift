import DuetSQL

final class UserDevice: Codable {
  var id: Id
  var userId: User.Id
  var deviceId: Device.Id
  var appVersion: String
  var username: String
  var fullUsername: String
  var numericId: Int
  var createdAt = Date()
  var updatedAt = Date()

  var user = Parent<User>.notLoaded
  var device = Parent<Device>.notLoaded
  var unlockRequests = Children<UnlockRequest>.notLoaded
  var suspendFilterRequests = Children<SuspendFilterRequest>.notLoaded

  init(
    id: Id = .init(),
    userId: User.Id,
    deviceId: Device.Id,
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
  }
}

// extensions

extension UserDevice {
  func user() async throws -> User {
    try await self.user.useLoaded(or: {
      try await Current.db.query(User.self)
        .where(.id == userId)
        .first()
    })
  }

  func adminDevice() async throws -> Device {
    try await self.device.useLoaded(or: {
      try await Current.db.query(Device.self)
        .where(.id == deviceId)
        .first()
    })
  }
}

extension UserDevice {
  func isOnline() async -> Bool {
    await Current.connectedApps.isUserDeviceOnline(self.id)
  }
}
