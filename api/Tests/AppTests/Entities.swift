@testable import App

enum Entities {
  @dynamicMemberLookup struct UserEntities {
    let model: User
    let token: UserToken
    let admin: Admin
    subscript<T>(dynamicMember keyPath: KeyPath<App.User, T>) -> T {
      model[keyPath: keyPath]
    }
  }

  static func user(
    config: (inout User) -> Void = { _ in },
    admin: (inout Admin) -> Void = { _ in }
  ) async throws -> UserEntities {
    let admin = try await Current.db.create(Admin.random(with: admin))
    let user = try await Current.db.create(User.random {
      config(&$0)
      $0.adminId = admin.id
    })
    let token = try await Current.db.create(UserToken(userId: user.id))
    return UserEntities(model: user, token: token, admin: admin)
  }
}
