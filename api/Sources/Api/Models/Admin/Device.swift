import DuetSQL
import Gertie

final class Device: Codable {
  var id: Id
  var adminId: Admin.Id
  var customName: String?
  var modelIdentifier: String
  var serialNumber: String
  var appReleaseChannel: ReleaseChannel
  var createdAt = Date()
  var updatedAt = Date()

  var admin = Parent<Admin>.notLoaded
  var userDevices = Children<UserDevice>.notLoaded

  init(
    id: Id = .init(),
    adminId: Admin.Id,
    customName: String? = nil,
    appReleaseChannel: ReleaseChannel = .stable,
    modelIdentifier: String,
    serialNumber: String
  ) {
    self.id = id
    self.adminId = adminId
    self.customName = customName
    self.appReleaseChannel = appReleaseChannel
    self.modelIdentifier = modelIdentifier
    self.serialNumber = serialNumber
  }
}

// loaders

extension Device {
  func admin() async throws -> Admin {
    try await admin.useLoaded(or: {
      try await Current.db.query(Admin.self)
        .where(.id == adminId)
        .first()
    })
  }

  func userDevices() async throws -> [UserDevice] {
    try await userDevices.useLoaded(or: {
      try await Current.db.query(UserDevice.self)
        .where(.deviceId == id)
        .all()
    })
  }
}
