import Duet

struct KeystrokeLine: Codable, Sendable {
  var id: Id
  var computerUserId: UserDevice.Id
  var appName: String
  var line: String
  var filterSuspended: Bool
  var createdAt: Date
  var deletedAt: Date?

  init(
    id: Id = .init(),
    computerUserId: UserDevice.Id,
    appName: String,
    line: String,
    filterSuspended: Bool = false,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.computerUserId = computerUserId
    self.appName = appName
    self.line = line
    self.filterSuspended = filterSuspended
    self.createdAt = createdAt
  }
}
