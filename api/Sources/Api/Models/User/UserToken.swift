import DuetSQL
import Tagged

final class UserToken: Codable {
  var id: Id
  var userId: User.Id
  var userDeviceId: UserDevice.Id? // TODO: why is this nullable?
  var value: Value
  var createdAt = Date()
  var updatedAt = Date()
  var deletedAt: Date?

  var user = Parent<User>.notLoaded
  var userDevice = OptionalParent<UserDevice>.notLoaded

  init(
    id: Id = .init(),
    userId: User.Id,
    userDeviceId: UserDevice.Id? = nil,
    value: Value = .init(rawValue: UUID.new())
  ) {
    self.id = id
    self.value = value
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
  func user() async throws -> User {
    try await user.useLoaded(or: {
      try await Current.db.query(User.self)
        .where(.id == userId)
        .first()
    })
  }

  func userDevice() async throws -> UserDevice? {
    try await userDevice.useLoaded(or: { () async throws -> UserDevice? in
      guard let userDeviceId else { return nil }
      return try await Current.db.query(UserDevice.self)
        .where(.id == userDeviceId)
        .first()
    })
  }
}
