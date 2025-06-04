import Dependencies

@testable import Api

@dynamicMemberLookup
class ChildEntities {
  var model: Child
  var parent: ParentEntities

  subscript<T>(dynamicMember keyPath: KeyPath<Child, T>) -> T {
    self.model[keyPath: keyPath]
  }

  init(model: Child, parent: ParentEntities) {
    self.model = model
    self.parent = parent
  }
}

@dynamicMemberLookup
struct ChildWithComputerEntities {
  var model: Child
  var computer: Device
  var computerUser: ComputerUser
  var token: MacAppToken
  var parent: ParentEntities

  var context: MacApp.ChildContext {
    .init(requestId: "mock-req-id", dashboardUrl: "/", user: self.model, token: self.token)
  }

  subscript<T>(dynamicMember keyPath: KeyPath<Child, T>) -> T {
    self.model[keyPath: keyPath]
  }
}

@dynamicMemberLookup
struct ChildWithIOSDeviceEntities {
  var model: Child
  var device: IOSApp.Device
  var token: IOSApp.Token
  var parent: ParentEntities

  var context: IOSApp.ChildContext {
    .init(requestId: "", dashboardUrl: "", child: self.model, device: self.device)
  }

  subscript<T>(dynamicMember keyPath: KeyPath<Child, T>) -> T {
    self.model[keyPath: keyPath]
  }
}

@dynamicMemberLookup
struct ParentEntities {
  var model: Admin
  var token: AdminToken

  var context: AdminContext {
    .init(requestId: "mock-req-id", dashboardUrl: "/", parent: self.model, ipAddress: nil)
  }

  subscript<T>(dynamicMember keyPath: KeyPath<Admin, T>) -> T {
    self.model[keyPath: keyPath]
  }
}

@dynamicMemberLookup
struct ParentWithKeychainEntities {
  var model: Admin
  var token: AdminToken
  var keychain: Keychain
  var key: Key

  var context: AdminContext {
    .init(requestId: "mock-req-id", dashboardUrl: "/", parent: self.model, ipAddress: nil)
  }

  subscript<T>(dynamicMember keyPath: KeyPath<Admin, T>) -> T {
    self.model[keyPath: keyPath]
  }
}

@dynamicMemberLookup
struct ParentWithOnboardedChildEntities {
  var model: Admin
  var token: AdminToken
  var child: Child
  var computerUser: ComputerUser
  var computer: Device

  var context: AdminContext {
    .init(requestId: "mock-req-id", dashboardUrl: "/", parent: self.model, ipAddress: nil)
  }

  subscript<T>(dynamicMember keyPath: KeyPath<Admin, T>) -> T {
    self.model[keyPath: keyPath]
  }
}

extension ApiTestCase {
  func parent(
    with config: (inout Admin) -> Void = { _ in }
  ) async throws -> ParentEntities {
    let parent = try await self.db.create(Admin.random(with: config))
    let token = try await self.db.create(AdminToken(parentId: parent.id))
    return ParentEntities(model: parent, token: token)
  }

  func parent<T>(
    with kp: WritableKeyPath<Admin, T>,
    of value: T
  ) async throws -> ParentEntities {
    try await self.parent(with: { $0[keyPath: kp] = value })
  }

  func child<T>(
    with kp: WritableKeyPath<Child, T>,
    of value: T
  ) async throws -> ChildEntities {
    try await self.child(with: { $0[keyPath: kp] = value })
  }

  func child(
    with childConfig: (inout Child) -> Void = { _ in },
    withParent parentConfig: (inout Admin) -> Void = { _ in }
  ) async throws -> ChildEntities {
    let parent = try await self.parent(with: parentConfig)
    let child = try await self.db.create(Child.random {
      childConfig(&$0)
      $0.parentId = parent.id
    })
    return ChildEntities(model: child, parent: parent)
  }

  func childWithIOSDevice() async throws -> ChildWithIOSDeviceEntities {
    let child = try await self.child()
    let iosDevice = try await self.db.create(IOSApp.Device.mock { $0.childId = child.id })
    let token = try await self.db.create(IOSApp.Token(deviceId: iosDevice.id))
    return .init(model: child.model, device: iosDevice, token: token, parent: child.parent)
  }

  func childWithComputer() async throws -> ChildWithComputerEntities {
    let child = try await self.child()
    let computer = try await self.db.create(Device.random {
      $0.parentId = child.parent.model.id
    })
    let computerUser = try await self.db.create(ComputerUser.random {
      $0.childId = child.model.id
      $0.computerId = computer.id
    })
    let token = try await self.db.create(MacAppToken(
      childId: child.model.id,
      computerUserId: computerUser.id
    ))
    return .init(
      model: child.model,
      computer: computer,
      computerUser: computerUser,
      token: token,
      parent: child.parent
    )
  }
}

extension ParentEntities {
  func withKeychain(
    config: (inout Keychain, inout Key) -> Void = { _, _ in }
  ) async throws -> ParentWithKeychainEntities {
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

extension ChildEntities {
  func withDevice(
    config: (inout ComputerUser) -> Void = { _ in },
    computer: (inout Device) -> Void = { _ in }
  ) async throws -> ChildWithComputerEntities {
    @Dependency(\.db) var db
    let device = try await db.create(Device.random {
      computer(&$0)
      $0.parentId = self.parent.id
    })
    let computerUser = try await db.create(ComputerUser.random {
      config(&$0)
      $0.childId = self.model.id
      $0.computerId = device.id
    })
    let token = try await db.create(MacAppToken(
      childId: self.model.id,
      computerUserId: computerUser.id
    ))
    return .init(
      model: self.model,
      computer: device,
      computerUser: computerUser,
      token: token,
      parent: self.parent
    )
  }
}
