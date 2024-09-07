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
  func devices(in db: any DuetSQL.Client) async throws -> [UserDevice] {
    try await UserDevice.query()
      .where(.userId == self.id)
      .all(in: db)
  }

  func keychains(in db: any DuetSQL.Client) async throws -> [Keychain] {
    let pivots = try await UserKeychain.query()
      .where(.userId == self.id)
      .all(in: db)
    return try await Keychain.query()
      .where(.id |=| pivots.map(\.keychainId))
      .all(in: db)
  }

  func admin(in db: any DuetSQL.Client) async throws -> Admin {
    try await Admin.query()
      .where(.id == self.adminId)
      .first(in: db)
  }
}
