import Dependencies
import DuetSQL

struct AdminContext: ResolverContext {
  let requestId: String
  let dashboardUrl: String
  let admin: Admin
  let ipAddress: String?

  @Dependency(\.db) var db
  @Dependency(\.env) var env

  @discardableResult
  func verifiedUser(from id: Child.Id) async throws -> Child {
    try await Child.query()
      .where(.id == id)
      .where(.parentId == self.admin.id)
      .first(in: self.db)
  }

  func users() async throws -> [Child] {
    try await Child.query()
      .where(.parentId == self.admin.id)
      .all(in: self.db)
  }

  func computerUsers() async throws -> [ComputerUser] {
    let users = try await self.users()
    return try await ComputerUser.query()
      .where(.childId |=| users.map(\.id))
      .all(in: self.db)
  }
}
