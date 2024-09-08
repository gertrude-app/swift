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
  func verifiedUser(from id: User.Id) async throws -> User {
    try await User.query()
      .where(.id == id)
      .where(.adminId == self.admin.id)
      .first(in: self.db)
  }

  func users() async throws -> [User] {
    try await User.query()
      .where(.adminId == self.admin.id)
      .all(in: self.db)
  }

  func userDevices() async throws -> [UserDevice] {
    let users = try await users()
    return try await users
      .concurrentMap { try await $0.devices(in: self.db) }
      .flatMap { $0 }
  }
}
