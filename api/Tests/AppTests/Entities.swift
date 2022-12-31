@testable import App

@dynamicMemberLookup struct UserEntities {
  let model: User
  let token: UserToken
  let admin: AdminEntities
  subscript<T>(dynamicMember keyPath: KeyPath<User, T>) -> T {
    model[keyPath: keyPath]
  }
}

@dynamicMemberLookup struct UserWithDeviceEntities {
  let model: User
  let device: Device
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
    .init(dashboardUrl: "/", admin: model)
  }

  subscript<T>(dynamicMember keyPath: KeyPath<Admin, T>) -> T {
    model[keyPath: keyPath]
  }
}

@dynamicMemberLookup struct AdminWithKeychainEntities {
  let model: Admin
  let token: AdminToken
  let keychain: Keychain
  let key: Key

  var context: AdminContext {
    .init(dashboardUrl: "/", admin: model)
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

extension AdminEntities {
  func withKeychain(
    config: (inout Keychain, inout Key) -> Void = { _, _ in }
  ) async throws -> AdminWithKeychainEntities {
    var keychain = Keychain.random
    keychain.authorId = model.id
    var key = Key.random
    key.keychainId = keychain.id
    config(&keychain, &key)
    try await Current.db.create(keychain)
    try await Current.db.create(key)
    return .init(model: model, token: token, keychain: keychain, key: key)
  }
}

extension UserEntities {
  func withDevice(
    config: (inout Device) -> Void = { _ in }
  ) async throws -> UserWithDeviceEntities {
    let device = try await Current.db.create(Device.random {
      config(&$0)
      $0.userId = model.id
    })
    return .init(model: model, device: device, token: token, admin: admin)
  }
}
