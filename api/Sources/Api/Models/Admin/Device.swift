import DuetSQL
import Gertie

struct Device: Codable, Sendable {
  var id: Id
  var adminId: Admin.Id
  var customName: String?
  var modelIdentifier: String
  var serialNumber: String
  var appReleaseChannel: ReleaseChannel
  var filterVersion: Semver?
  var osVersion: Semver?
  var createdAt = Date()
  var updatedAt = Date()

  init(
    id: Id = .init(),
    adminId: Admin.Id,
    customName: String? = nil,
    appReleaseChannel: ReleaseChannel = .stable,
    filterVersion: Semver? = nil,
    osVersion: Semver? = nil,
    modelIdentifier: String,
    serialNumber: String
  ) {
    self.id = id
    self.adminId = adminId
    self.customName = customName
    self.appReleaseChannel = appReleaseChannel
    self.modelIdentifier = modelIdentifier
    self.serialNumber = serialNumber
    self.filterVersion = filterVersion
    self.osVersion = osVersion
  }
}

// loaders

extension Device {
  func admin() async throws -> Admin {
    try await Admin.query()
      .where(.id == self.adminId)
      .first()
  }

  func userDevices() async throws -> [UserDevice] {
    try await UserDevice.query()
      .where(.deviceId == self.id)
      .all()
  }
}
