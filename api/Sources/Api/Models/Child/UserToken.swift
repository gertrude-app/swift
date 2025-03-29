import Dependencies
import DuetSQL
import Tagged

struct UserToken: Codable, Sendable {
  var id: Id
  var childId: Child.Id
  var computerUserId: UserDevice.Id
  var value: Value
  var createdAt = Date()
  var updatedAt = Date()
  var deletedAt: Date?

  init(
    id: Id = .init(),
    childId: Child.Id,
    computerUserId: UserDevice.Id,
    value: Value? = nil
  ) {
    @Dependency(\.uuid) var uuid
    self.id = id
    self.value = value ?? .init(uuid())
    self.childId = childId
    self.computerUserId = computerUserId
  }
}

// extensions

extension UserToken {
  typealias Value = Tagged<(UserToken, value: ()), UUID>
}

// loaders

extension UserToken {
  func user(in db: any DuetSQL.Client) async throws -> Child {
    try await Child.query()
      .where(.id == self.childId)
      .first(in: db)
  }

  func userDevice(in db: any DuetSQL.Client) async throws -> UserDevice {
    try await UserDevice.query()
      .where(.id == self.computerUserId)
      .first(in: db)
  }
}
