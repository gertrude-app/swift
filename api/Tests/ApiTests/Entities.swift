import Dependencies

@testable import Api

@dynamicMemberLookup
class UserEntities {
  var model: User
  var admin: AdminEntities

  subscript<T>(dynamicMember keyPath: KeyPath<User, T>) -> T {
    self.model[keyPath: keyPath]
  }

  init(model: User, admin: AdminEntities) {
    self.model = model
    self.admin = admin
  }
}

@dynamicMemberLookup
struct UserWithDeviceEntities {
  var model: User
  var adminDevice: Device
  var device: ComputerUser
  var token: MacAppToken
  var admin: AdminEntities

  var context: MacApp.ChildContext {
    .init(requestId: "mock-req-id", dashboardUrl: "/", user: self.model, token: self.token)
  }

  subscript<T>(dynamicMember keyPath: KeyPath<User, T>) -> T {
    self.model[keyPath: keyPath]
  }
}

@dynamicMemberLookup
struct ChildWithIOSDeviceEntities {
  var model: User
  var device: IOSApp.Device
  var token: IOSApp.Token
  var parent: AdminEntities

  var context: IOSApp.ChildContext {
    .init(requestId: "", dashboardUrl: "", child: self.model, device: self.device)
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
  var userDevice: ComputerUser
  var adminDevice: Device

  var context: AdminContext {
    .init(requestId: "mock-req-id", dashboardUrl: "/", admin: self.model, ipAddress: nil)
  }

  subscript<T>(dynamicMember keyPath: KeyPath<Admin, T>) -> T {
    self.model[keyPath: keyPath]
  }
}

extension ApiTestCase {
  func admin(
    with config: (inout Admin) -> Void = { _ in }
  ) async throws -> AdminEntities {
    let admin = try await self.db.create(Admin.random(with: config))
    let token = try await self.db.create(AdminToken(parentId: admin.id))
    return AdminEntities(model: admin, token: token)
  }

  func admin<T>(
    with kp: WritableKeyPath<Admin, T>,
    of value: T
  ) async throws -> AdminEntities {
    try await self.admin(with: { $0[keyPath: kp] = value })
  }

  func user<T>(
    with kp: WritableKeyPath<User, T>,
    of value: T
  ) async throws -> UserEntities {
    try await self.user(with: { $0[keyPath: kp] = value })
  }

  func user(
    with userConfig: (inout User) -> Void = { _ in },
    withAdmin adminConfig: (inout Admin) -> Void = { _ in }
  ) async throws -> UserEntities {
    let admin = try await self.admin(with: adminConfig)
    let user = try await self.db.create(User.random {
      userConfig(&$0)
      $0.parentId = admin.id
    })
    return UserEntities(model: user, admin: admin)
  }

  func childWithIOSDevice() async throws -> ChildWithIOSDeviceEntities {
    let child = try await self.user()
    let iosDevice = try await self.db.create(IOSApp.Device.mock { $0.childId = child.id })
    let token = try await self.db.create(IOSApp.Token(deviceId: iosDevice.id))
    return .init(model: child.model, device: iosDevice, token: token, parent: child.admin)
  }

  func userWithDevice() async throws -> UserWithDeviceEntities {
    let user = try await self.user()
    let device = try await self.db.create(Device.random {
      $0.parentId = user.admin.model.id
    })
    let userDevice = try await self.db.create(ComputerUser.random {
      $0.childId = user.model.id
      $0.computerId = device.id
    })
    let token = try await self.db.create(MacAppToken(
      childId: user.id,
      computerUserId: userDevice.id
    ))
    return .init(
      model: user.model,
      adminDevice: device,
      device: userDevice,
      token: token,
      admin: user.admin
    )
  }
}

extension AdminEntities {
  func withKeychain(
    config: (inout Keychain, inout Key) -> Void = { _, _ in }
  ) async throws -> AdminWithKeychainEntities {
    @Dependency(\.db) var db
    var keychain = Keychain.random
    keychain.parentId = self.model.id
    var key = Key.random
    key.keychainId = keychain.id
    config(&keychain, &key)
    try await db.create(keychain)
    try await db.create(key)
    return .init(model: self.model, token: self.token, keychain: keychain, key: key)
  }
}

extension UserEntities {
  func withDevice(
    config: (inout ComputerUser) -> Void = { _ in },
    adminDevice: (inout Device) -> Void = { _ in }
  ) async throws -> UserWithDeviceEntities {
    @Dependency(\.db) var db
    let device = try await db.create(Device.random {
      adminDevice(&$0)
      $0.parentId = self.admin.id
    })
    let userDevice = try await db.create(ComputerUser.random {
      config(&$0)
      $0.childId = self.model.id
      $0.computerId = device.id
    })
    let token = try await db.create(MacAppToken(
      childId: self.model.id,
      computerUserId: userDevice.id
    ))
    return .init(
      model: self.model,
      adminDevice: device,
      device: userDevice,
      token: token,
      admin: self.admin
    )
  }
}
