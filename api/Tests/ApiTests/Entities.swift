@testable import Api

@dynamicMemberLookup
class UserEntities {
  var model: User
  var token: UserToken
  var admin: AdminEntities

  var context: UserContext {
    .init(requestId: "mock-req-id", dashboardUrl: "/", user: self.model, token: self.token)
  }

  subscript<T>(dynamicMember keyPath: KeyPath<User, T>) -> T {
    self.model[keyPath: keyPath]
  }

  init(model: User, token: UserToken, admin: AdminEntities) {
    self.model = model
    self.token = token
    self.admin = admin
  }
}

@dynamicMemberLookup
struct UserWithDeviceEntities {
  var model: User
  var adminDevice: Device
  var device: UserDevice
  var token: UserToken
  var admin: AdminEntities

  var context: UserContext {
    .init(requestId: "mock-req-id", dashboardUrl: "/", user: self.model, token: self.token)
  }

  subscript<T>(dynamicMember keyPath: KeyPath<User, T>) -> T {
    self.model[keyPath: keyPath]
  }
}

@dynamicMemberLookup
struct AdminEntities {
  var model: Admin
  var token: AdminToken

  var context: AdminContext {
    .init(requestId: "mock-req-id", dashboardUrl: "/", admin: self.model, ipAddress: nil)
  }

  subscript<T>(dynamicMember keyPath: KeyPath<Admin, T>) -> T {
    self.model[keyPath: keyPath]
  }
}

@dynamicMemberLookup
struct AdminWithKeychainEntities {
  var model: Admin
  var token: AdminToken
  var keychain: Keychain
  var key: Key

  var context: AdminContext {
    .init(requestId: "mock-req-id", dashboardUrl: "/", admin: self.model, ipAddress: nil)
  }

  subscript<T>(dynamicMember keyPath: KeyPath<Admin, T>) -> T {
    self.model[keyPath: keyPath]
  }
}

@dynamicMemberLookup
struct AdminWithOnboardedChildEntities {
  var model: Admin
  var token: AdminToken
  var child: User
  var userDevice: UserDevice
  var adminDevice: Device

  var context: AdminContext {
    .init(requestId: "mock-req-id", dashboardUrl: "/", admin: self.model, ipAddress: nil)
  }

  subscript<T>(dynamicMember keyPath: KeyPath<Admin, T>) -> T {
    self.model[keyPath: keyPath]
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
    keychain.authorId = self.model.id
    var key = Key.random
    key.keychainId = keychain.id
    config(&keychain, &key)
    try await Current.db.create(keychain)
    try await Current.db.create(key)
    return .init(model: self.model, token: self.token, keychain: keychain, key: key)
  }

  func withOnboardedChild(
    config: (inout User, inout UserDevice, inout Device) -> Void = { _, _, _ in }
  ) async throws -> AdminWithOnboardedChildEntities {
    var child = User.random { $0.adminId = model.id }
    var adminDevice = Device.random { $0.adminId = model.id }
    var userDevice = UserDevice.random {
      $0.userId = child.id
      $0.deviceId = adminDevice.id
    }
    config(&child, &userDevice, &adminDevice)
    try await Current.db.create(child)
    try await Current.db.create(adminDevice)
    try await Current.db.create(userDevice)
    return .init(
      model: self.model,
      token: self.token,
      child: child,
      userDevice: userDevice,
      adminDevice: adminDevice
    )
  }
}

extension UserEntities {
  func withDevice(
    config: (inout UserDevice) -> Void = { _ in },
    adminDevice: (inout Device) -> Void = { _ in }
  ) async throws -> UserWithDeviceEntities {
    let device = try await Current.db.create(Device.random {
      adminDevice(&$0)
      $0.adminId = admin.id
    })
    let userDevice = try await Current.db.create(UserDevice.random {
      config(&$0)
      $0.userId = model.id
      $0.deviceId = device.id
    })
    self.token.userDeviceId = userDevice.id
    try await Current.db.update(self.token)
    return .init(
      model: self.model,
      adminDevice: device,
      device: userDevice,
      token: self.token,
      admin: self.admin
    )
  }
}
