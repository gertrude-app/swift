import Duet

struct AdminVerifiedNotificationMethod: Codable, Sendable {
  var id: Id
  var adminId: Admin.Id
  var config: Config
  var createdAt = Date()

  init(id: Id = .init(), adminId: Admin.Id, config: Config) {
    self.id = id
    self.adminId = adminId
    self.config = config
  }
}

// extensions

extension AdminVerifiedNotificationMethod {
  enum Config: Codable, Equatable, Sendable {
    case slack(channelId: String, channelName: String, token: String)
    case email(email: String)
    case text(phoneNumber: String)
  }
}
