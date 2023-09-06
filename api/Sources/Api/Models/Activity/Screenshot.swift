import Duet

final class Screenshot: Codable {
  var id: Id
  var userDeviceId: UserDevice.Id
  var url: String
  var width: Int
  var height: Int
  var filterSuspended: Bool
  var createdAt: Date
  var deletedAt: Date?

  var userDevice = Parent<UserDevice>.notLoaded

  init(
    id: Id = .init(),
    userDeviceId: UserDevice.Id,
    url: String,
    width: Int,
    height: Int,
    filterSuspended: Bool = false,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.userDeviceId = userDeviceId
    self.url = url
    self.width = width
    self.height = height
    self.filterSuspended = filterSuspended
    self.createdAt = createdAt
  }
}
