import DuetSQL
import Gertie

struct Computer: Codable, Sendable {
  var id: Id
  var parentId: Parent.Id
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
    parentId: Parent.Id,
    customName: String? = nil,
    appReleaseChannel: ReleaseChannel = .stable,
    filterVersion: Semver? = nil,
    osVersion: Semver? = nil,
    modelIdentifier: String,
    serialNumber: String,
  ) {
    self.id = id
    self.parentId = parentId
    self.customName = customName
    self.appReleaseChannel = appReleaseChannel
    self.modelIdentifier = modelIdentifier
    self.serialNumber = serialNumber
    self.filterVersion = filterVersion
    self.osVersion = osVersion
  }
}

// loaders

extension Computer {
  func parent(in db: any DuetSQL.Client) async throws -> Parent {
    try await Parent.query()
      .where(.id == self.parentId)
      .first(in: db)
  }

  func computerUsers(in db: any DuetSQL.Client) async throws -> [ComputerUser] {
    try await ComputerUser.query()
      .where(.computerId == self.id)
      .all(in: db)
  }
}
