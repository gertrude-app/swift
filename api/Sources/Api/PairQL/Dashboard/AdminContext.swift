import Dependencies
import DuetSQL

struct AdminContext: ResolverContext {
  let requestId: String
  let dashboardUrl: String
  let parent: Admin
  let ipAddress: String?

  @Dependency(\.db) var db
  @Dependency(\.env) var env

  @discardableResult
  func verifiedChild(from id: Child.Id) async throws -> Child {
    try await Child.query()
      .where(.id == id)
      .where(.parentId == self.parent.id)
      .first(in: self.db)
  }

  func children() async throws -> [Child] {
    try await Child.query()
      .where(.parentId == self.parent.id)
      .all(in: self.db)
  }

  func computerUsers() async throws -> [ComputerUser] {
    let users = try await self.children()
    return try await ComputerUser.query()
      .where(.childId |=| users.map(\.id))
      .all(in: self.db)
  }
}
