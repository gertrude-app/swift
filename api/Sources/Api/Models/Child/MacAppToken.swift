import Dependencies
import DuetSQL
import Tagged

struct MacAppToken: Codable, Sendable {
  var id: Id
  var childId: Child.Id
  var computerUserId: ComputerUser.Id
  var value: Value
  var createdAt = Date()
  var updatedAt = Date()
  var deletedAt: Date?

  init(
    id: Id = .init(),
    childId: Child.Id,
    computerUserId: ComputerUser.Id,
    value: Value? = nil,
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
  func child(in db: any DuetSQL.Client) async throws -> Child {
    try await Child.query()
      .where(.id == self.childId)
      .first(in: db)
  }

  func computerUser(in db: any DuetSQL.Client) async throws -> ComputerUser {
    try await ComputerUser.query()
      .where(.id == self.computerUserId)
      .first(in: db)
  }
}
