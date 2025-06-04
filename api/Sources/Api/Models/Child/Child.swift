import DuetSQL
import Gertie

struct Child: Codable, Sendable {
  var id: Id
  var parentId: Admin.Id
  var name: String
  var keyloggingEnabled: Bool
  var screenshotsEnabled: Bool
  var screenshotsResolution: Int
  var screenshotsFrequency: Int
  var showSuspensionActivity: Bool
  var downtime: PlainTimeWindow?
  var createdAt = Date()
  var updatedAt = Date()

  init(
    id: Id = .init(),
    parentId: Admin.Id,
    name: String,
    keyloggingEnabled: Bool = false,
    screenshotsEnabled: Bool = false,
    screenshotsResolution: Int = 1200,
    screenshotsFrequency: Int = 60,
    showSuspensionActivity: Bool = true,
    downtime: PlainTimeWindow? = nil
  ) {
    self.id = id
    self.parentId = parentId
    self.name = name
    self.keyloggingEnabled = keyloggingEnabled
    self.screenshotsEnabled = screenshotsEnabled
    self.screenshotsResolution = screenshotsResolution
    self.screenshotsFrequency = screenshotsFrequency
    self.showSuspensionActivity = showSuspensionActivity
    self.downtime = downtime
  }
}

// loaders

extension Child {
  func computerUsers(in db: any DuetSQL.Client) async throws -> [ComputerUser] {
    try await ComputerUser.query()
      .where(.childId == self.id)
      .all(in: db)
  }

  func iosDevices(in db: any DuetSQL.Client) async throws -> [IOSApp.Device] {
    try await IOSApp.Device.query()
      .where(.childId == self.id)
      .all(in: db)
  }

  func keychains(in db: any DuetSQL.Client) async throws -> [Keychain] {
    let pivots = try await ChildKeychain.query()
      .where(.childId == self.id)
      .all(in: db)
    return try await Keychain.query()
      .where(.id |=| pivots.map(\.keychainId))
      .all(in: db)
  }

  func admin(in db: any DuetSQL.Client) async throws -> Admin {
    try await Admin.query()
      .where(.id == self.parentId)
      .first(in: db)
  }

  func blockedApps(in db: any DuetSQL.Client) async throws -> [UserBlockedApp] {
    try await UserBlockedApp.query()
      .where(.childId == self.id)
      .all(in: db)
  }
}
