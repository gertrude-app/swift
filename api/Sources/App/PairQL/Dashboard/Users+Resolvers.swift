import DashboardRoute
import DuetSQL

extension GetUser: PairResolver {
  static func resolve(for id: UUID, in context: AdminContext) async throws -> Output {
    let user = try await Current.db.query(User.self)
      .where(.id == id)
      .where(.adminId == context.admin.id)
      .first()
    return try await Output(from: user)
  }
}

extension GetUsers: NoInputPairResolver {
  static func resolve(in context: AdminContext) async throws -> Output {
    let users = try await Current.db.query(User.self)
      .where(.adminId == context.admin.id)
      .all()

    return try await users.concurrentMap { try await .init(from: $0) }
  }
}

extension DeleteUser: PairResolver {
  static func resolve(for id: UUID, in context: AdminContext) async throws -> Output {
    try await Current.db.query(User.self)
      .where(.id == id)
      .where(.adminId == context.admin.id)
      .delete()
    return .true
  }
}

extension SaveUser: PairResolver {
  static func resolve(for input: Input, in context: AdminContext) async throws -> Output {
    let user: User
    if input.isNew {
      user = try await Current.db.create(User(
        id: .init(input.id),
        adminId: .init(input.adminId),
        name: input.name,
        keyloggingEnabled: input.keyloggingEnabled,
        screenshotsEnabled: input.screenshotsEnabled,
        screenshotsResolution: input.screenshotsResolution,
        screenshotsFrequency: input.screenshotsFrequency
      ))
    } else {
      user = try await Current.db.find(User.Id(input.id))
      user.name = input.name
      user.keyloggingEnabled = input.keyloggingEnabled
      user.screenshotsEnabled = input.screenshotsEnabled
      user.screenshotsResolution = input.screenshotsResolution
      user.screenshotsFrequency = input.screenshotsFrequency
      try await Current.db.update(user)
    }

    let keychainIds = try await Current.db.query(UserKeychain.self)
      .where(.userId == user.id)
      .all()
      .map(\.keychainId.rawValue)

    if keychainIds.elementsEqual(input.keychainIds) {
      // TODO: dispatch event
      return .init(true)
    }

    try await Current.db.query(UserKeychain.self)
      .where(.userId == user.id)
      .delete()

    let pivots = input.keychainIds
      .map { UserKeychain(userId: user.id, keychainId: .init(rawValue: $0)) }

    try await Current.db.create(pivots)

    // TODO: dispatch event
    return .init(true)
  }
}

extension GetUser.Keychain {
  init(from keychain: App.Keychain) async throws {
    let numKeys = try await Current.db.count(
      Key.self,
      where: .keychainId == keychain.id,
      withSoftDeleted: false
    )
    self.init(
      id: keychain.id.rawValue,
      authorId: keychain.authorId.rawValue,
      name: keychain.name,
      description: keychain.description,
      isPublic: keychain.isPublic,
      numKeys: numKeys
    )
  }
}

extension GetUser.Output {
  init(from user: User) async throws {
    let pivots = try await Current.db.query(UserKeychain.self)
      .where(.userId == user.id)
      .all()

    let keychains = try await Current.db.query(Keychain.self)
      .where(.id |=| pivots.map(\.keychainId))
      .all()

    async let userKeychains = keychains
      .concurrentMap { try await GetUser.Keychain(from: $0) }

    async let devices = Current.db.query(Device.self)
      .where(.userId == user.id)
      .all()
      .map { device in
        GetUser.Device(
          id: device.id.rawValue,
          isOnline: device.isOnline,
          modelFamily: device.model.family,
          modelTitle: device.model.shortDescription
        )
      }

    self.init(
      id: user.id.rawValue,
      name: user.name,
      keyloggingEnabled: user.keyloggingEnabled,
      screenshotsEnabled: user.screenshotsEnabled,
      screenshotsResolution: user.screenshotsResolution,
      screenshotsFrequency: user.screenshotsFrequency,
      keychains: try await userKeychains,
      devices: try await devices,
      createdAt: user.createdAt
    )
  }
}
