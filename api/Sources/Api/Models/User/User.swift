import DuetSQL

struct User: Codable, Sendable {
  var id: Id
  var adminId: Admin.Id
  var name: String
  var keyloggingEnabled: Bool
  var screenshotsEnabled: Bool
  var screenshotsResolution: Int
  var screenshotsFrequency: Int
  var showSuspensionActivity: Bool
  var createdAt = Date()
  var updatedAt = Date()
  var deletedAt: Date?

  init(
    id: Id = .init(),
    adminId: Admin.Id,
    name: String,
    keyloggingEnabled: Bool = false,
    screenshotsEnabled: Bool = false,
    screenshotsResolution: Int = 1200,
    screenshotsFrequency: Int = 60,
    showSuspensionActivity: Bool = true
  ) {
    self.id = id
    self.adminId = adminId
    self.name = name
    self.keyloggingEnabled = keyloggingEnabled
    self.screenshotsEnabled = screenshotsEnabled
    self.screenshotsResolution = screenshotsResolution
    self.screenshotsFrequency = screenshotsFrequency
    self.showSuspensionActivity = showSuspensionActivity
  }
}

// loaders

extension User {
  func devices() async throws -> [UserDevice] {
    try await Current.db.query(UserDevice.self)
      .where(.userId == self.id)
      .all()
  }

  func keychains() async throws -> [Keychain] {
    let pivots = try await Current.db.query(UserKeychain.self)
      .where(.userId == self.id)
      .all()
    return try await Current.db.query(Keychain.self)
      .where(.id |=| pivots.map(\.keychainId))
      .all()
  }

  func admin() async throws -> Admin {
    try await Current.db.query(Admin.self)
      .where(.id == self.adminId)
      .first()
  }
}
