import Duet

struct KeystrokeLine: Codable, Sendable {
  var id: Id
  var computerUserId: ComputerUser.Id
  var appName: String
  var line: String
  var filterSuspended: Bool
  var flagged: Date?
  var createdAt: Date
  var deletedAt: Date?

  init(
    id: Id = .init(),
    computerUserId: ComputerUser.Id,
    appName: String,
    line: String,
    filterSuspended: Bool = false,
    flagged: Date? = nil,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.computerUserId = computerUserId
    self.appName = appName
    self.line = line
    self.filterSuspended = filterSuspended
    self.flagged = flagged
    self.createdAt = createdAt
  }
}
