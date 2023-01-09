import DuetSQL

final class User: Codable {
  var id: Id
  var adminId: Admin.Id
  var name: String
  var keyloggingEnabled: Bool
  var screenshotsEnabled: Bool
  var screenshotsResolution: Int
  var screenshotsFrequency: Int
  var createdAt = Date()
  var updatedAt = Date()
  var deletedAt: Date?

  var admin = Parent<Admin>.notLoaded
  var devices = Children<Device>.notLoaded
  var tokens = Children<UserToken>.notLoaded
  var keychains = Siblings<Keychain>.notLoaded

  init(
    id: Id = .init(),
    adminId: Admin.Id,
    name: String,
    keyloggingEnabled: Bool = false,
    screenshotsEnabled: Bool = false,
    screenshotsResolution: Int = 1200,
    screenshotsFrequency: Int = 60
  ) {
    self.id = id
    self.adminId = adminId
    self.name = name
    self.keyloggingEnabled = keyloggingEnabled
    self.screenshotsEnabled = screenshotsEnabled
    self.screenshotsResolution = screenshotsResolution
    self.screenshotsFrequency = screenshotsFrequency
  }
}

// loaders

extension User {
  func devices() async throws -> [Device] {
    try await devices.useLoaded(or: {
      try await Current.db.query(Device.self)
        .where(.userId == id)
        .all()
    })
  }

  func keychains() async throws -> [Keychain] {
    try await keychains.useLoaded(or: {
      let pivots = try await Current.db.query(UserKeychain.self)
        .where(.userId == id)
        .all()
      return try await Current.db.query(Keychain.self)
        .where(.id |=| pivots.map(\.keychainId))
        .all()
    })
  }

  func admin() async throws -> Admin {
    try await admin.useLoaded(or: {
      try await Current.db.query(Admin.self)
        .where(.id == adminId)
        .first()
    })
  }
}
