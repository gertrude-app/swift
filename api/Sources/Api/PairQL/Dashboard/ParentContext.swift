import Dependencies
import DuetSQL

struct ParentContext: ResolverContext {
  let requestId: String
  let dashboardUrl: String
  let parent: Parent
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
    let children = try await self.children()
    return try await ComputerUser.query()
      .where(.childId |=| children.map(\.id))
      .all(in: self.db)
  }
}
