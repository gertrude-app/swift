import DuetSQL

struct AdminContext: ResolverContext {
  let requestId: String
  let dashboardUrl: String
  let admin: Admin

  @discardableResult
  func verifiedUser(from id: User.Id) async throws -> User {
    try await Current.db.query(User.self)
      .where(.id == id)
      .where(.adminId == self.admin.id)
      .first()
  }

  func users() async throws -> [User] {
    try await Current.db.query(User.self)
      .where(.adminId == self.admin.id)
      .all()
  }

  func userDevices() async throws -> [UserDevice] {
    let users = try await users()
    return try await users
      .concurrentMap { try await $0.devices() }
      .flatMap { $0 }
  }
}
