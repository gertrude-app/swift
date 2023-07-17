import Duet

final class Screenshot: Codable {
  var id: Id
  var userDeviceId: UserDevice.Id
  var url: String
  var width: Int
  var height: Int
  var createdAt: Date
  var deletedAt: Date?

  var userDevice = Parent<UserDevice>.notLoaded

  init(
    id: Id = .init(),
    userDeviceId: UserDevice.Id,
    url: String,
    width: Int,
    height: Int,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.url = url
    self.width = width
    self.height = height
    self.userDeviceId = userDeviceId
    self.createdAt = createdAt
  }
}
