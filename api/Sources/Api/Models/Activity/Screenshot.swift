import Duet

struct Screenshot: Codable, Sendable {
  var id: Id
  var computerUserId: ComputerUser.Id
  var url: String
  var width: Int
  var height: Int
  var filterSuspended: Bool
  var flagged: Date?
  var createdAt: Date
  var deletedAt: Date?

  init(
    id: Id = .init(),
    computerUserId: ComputerUser.Id,
    url: String,
    width: Int,
    height: Int,
    filterSuspended: Bool = false,
    flagged: Date? = nil,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.computerUserId = computerUserId
    self.url = url
    self.width = width
    self.height = height
    self.filterSuspended = filterSuspended
    self.flagged = flagged
    self.createdAt = createdAt
  }
}
