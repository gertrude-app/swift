import DuetSQL
import Gertie

struct ComputerUser: Codable, Sendable, Equatable {
  var id: Id
  var childId: Child.Id
  var computerId: Computer.Id
  var isAdmin: Bool?
  var appVersion: String
  var username: String
  var fullUsername: String
  var numericId: Int
  var createdAt = Date()
  var updatedAt = Date()

  init(
    id: Id = .init(),
    childId: Child.Id,
    computerId: Computer.Id,
    isAdmin: Bool?,
    appVersion: String,
    username: String,
    fullUsername: String,
    numericId: Int,
  ) {
    self.id = id
    self.childId = childId
    self.computerId = computerId
    self.appVersion = appVersion
    self.username = username
    self.fullUsername = fullUsername
    self.numericId = numericId
    self.isAdmin = isAdmin
  }
}

// extensions

extension ComputerUser {
  var appSemver: Semver {
    Semver(self.appVersion)!
  }

  func child(in db: any DuetSQL.Client) async throws -> Child {
    try await Child.query()
      .where(.id == self.childId)
      .first(in: db)
  }

  func computer(in db: any DuetSQL.Client) async throws -> Computer {
    try await Computer.query()
      .where(.id == self.computerId)
      .first(in: db)
  }
}

extension ComputerUser {
  func status() async -> ChildComputerStatus {
    await with(dependency: \.websockets).status(self.id)
  }
}
