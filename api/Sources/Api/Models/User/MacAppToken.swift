import Dependencies
import DuetSQL
import Tagged

struct MacAppToken: Codable, Sendable {
  var id: Id
  var childId: User.Id
  var computerUserId: ComputerUser.Id
  var value: Value
  var createdAt = Date()
  var updatedAt = Date()
  var deletedAt: Date?

  init(
    id: Id = .init(),
    childId: User.Id,
    computerUserId: ComputerUser.Id,
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

extension MacAppToken {
  typealias Value = Tagged<(MacAppToken, value: ()), UUID>
}

// loaders

extension MacAppToken {
  func user(in db: any DuetSQL.Client) async throws -> User {
    try await User.query()
      .where(.id == self.childId)
      .first(in: db)
  }

  func computerUser(in db: any DuetSQL.Client) async throws -> ComputerUser {
    try await ComputerUser.query()
      .where(.id == self.computerUserId)
      .first(in: db)
  }
}
