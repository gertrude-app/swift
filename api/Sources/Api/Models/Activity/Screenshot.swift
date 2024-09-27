import Duet

struct Screenshot: Codable, Sendable {
  var id: Id
  var userDeviceId: UserDevice.Id
  var url: String
  var width: Int
  var height: Int
  var displayId: Int?
  var filterSuspended: Bool
  var createdAt: Date
  var deletedAt: Date?

  init(
    id: Id = .init(),
    userDeviceId: UserDevice.Id,
    url: String,
    width: Int,
    height: Int,
    displayId: Int? = nil,
    filterSuspended: Bool = false,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.userDeviceId = userDeviceId
    self.url = url
    self.width = width
    self.height = height
    self.displayId = displayId
    self.filterSuspended = filterSuspended
    self.createdAt = createdAt
  }
}
