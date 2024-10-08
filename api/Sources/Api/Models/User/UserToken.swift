import Dependencies
import DuetSQL
import Tagged

struct UserToken: Codable, Sendable {
  var id: Id
  var userId: User.Id
  var userDeviceId: UserDevice.Id
  var value: Value
  var createdAt = Date()
  var updatedAt = Date()
  var deletedAt: Date?

  init(
    id: Id = .init(),
    userId: User.Id,
    userDeviceId: UserDevice.Id,
    value: Value? = nil
  ) {
    @Dependency(\.uuid) var uuid
    self.id = id
    self.value = value ?? .init(uuid())
    self.userId = userId
    self.userDeviceId = userDeviceId
  }
}

// extensions

extension UserToken {
  typealias Value = Tagged<(UserToken, value: ()), UUID>
}

// loaders

extension UserToken {
  func user(in db: any DuetSQL.Client) async throws -> User {
    try await User.query()
      .where(.id == self.userId)
      .first(in: db)
  }

  func userDevice(in db: any DuetSQL.Client) async throws -> UserDevice {
    try await UserDevice.query()
      .where(.id == self.userDeviceId)
      .first(in: db)
  }
}
