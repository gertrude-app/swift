@testable import App

@dynamicMemberLookup struct UserEntities {
  let model: User
  let token: UserToken
  let admin: AdminEntities
  subscript<T>(dynamicMember keyPath: KeyPath<User, T>) -> T {
    model[keyPath: keyPath]
  }
}

@dynamicMemberLookup struct AdminEntities {
  let model: Admin
  let token: AdminToken

  var context: AdminContext {
    .init(request: .init(), admin: model)
  }

  subscript<T>(dynamicMember keyPath: KeyPath<Admin, T>) -> T {
    model[keyPath: keyPath]
  }
}

enum Entities {
  static func admin(
    config: (inout Admin) -> Void = { _ in }
  ) async throws -> AdminEntities {
    let admin = try await Current.db.create(Admin.random(with: config))
    let token = try await Current.db.create(AdminToken(adminId: admin.id))
    return AdminEntities(model: admin, token: token)
  }

  static func user(
    config: (inout User) -> Void = { _ in },
    admin: (inout Admin) -> Void = { _ in }
  ) async throws -> UserEntities {
    let admin = try await Self.admin(config: admin)
    let user = try await Current.db.create(User.random {
      config(&$0)
      $0.adminId = admin.id
    })
    let token = try await Current.db.create(UserToken(userId: user.id))
    return UserEntities(model: user, token: token, admin: admin)
  }
}
