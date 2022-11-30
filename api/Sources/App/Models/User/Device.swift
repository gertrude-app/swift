import Duet

final class Device: Codable {
  var id: Id
  var userId: User.Id
  var appVersion: String
  var customName: String?
  var hostname: String?
  var modelIdentifier: String
  var username: String
  var fullUsername: String
  var numericId: Int
  var serialNumber: String
  var createdAt = Date()
  var updatedAt = Date()

  var user = Parent<User>.notLoaded
  var unlockRequests = Children<UnlockRequest>.notLoaded
  var suspendFilterRequests = Children<SuspendFilterRequest>.notLoaded

  init(
    id: Id = .init(),
    userId: User.Id,
    appVersion: String,
    customName: String? = nil,
    hostname: String? = nil,
    modelIdentifier: String,
    username: String,
    fullUsername: String,
    numericId: Int,
    serialNumber: String
  ) {
    self.id = id
    self.userId = userId
    self.appVersion = appVersion
    self.customName = customName
    self.hostname = hostname
    self.modelIdentifier = modelIdentifier
    self.username = username
    self.fullUsername = fullUsername
    self.numericId = numericId
    self.serialNumber = serialNumber
  }
}
