import Duet

struct AdminVerifiedNotificationMethod: Codable, Sendable {
  var id: Id
  var parentId: Admin.Id
  var config: Config
  var createdAt = Date()

  init(id: Id = .init(), parentId: Admin.Id, config: Config) {
    self.id = id
    self.parentId = parentId
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
