import Duet

struct Screenshot: Codable, Sendable {
  var id: Id
  var computerUserId: UserDevice.Id
  var url: String
  var width: Int
  var height: Int
  var filterSuspended: Bool
  var createdAt: Date
  var deletedAt: Date?

  init(
    id: Id = .init(),
    computerUserId: UserDevice.Id,
    url: String,
    width: Int,
    height: Int,
    filterSuspended: Bool = false,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.computerUserId = computerUserId
    self.url = url
    self.width = width
    self.height = height
    self.filterSuspended = filterSuspended
    self.createdAt = createdAt
  }
}
