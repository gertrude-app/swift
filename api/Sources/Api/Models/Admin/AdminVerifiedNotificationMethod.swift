import Duet

final class AdminVerifiedNotificationMethod: Codable {
  var id: Id
  var adminId: Admin.Id
  var method: NotificationMethod
  var createdAt = Date()

  var admin = Parent<Admin>.notLoaded

  init(id: Id = .init(), adminId: Admin.Id, method: NotificationMethod) {
    self.id = id
    self.adminId = adminId
    self.method = method
  }
}
