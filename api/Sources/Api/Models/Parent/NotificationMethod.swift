import Duet

extension Parent {
  struct NotificationMethod: Codable, Sendable {
    var id: Id
    var parentId: Parent.Id
    var config: Config
    var createdAt = Date()

    init(id: Id = .init(), parentId: Parent.Id, config: Config) {
      self.id = id
      self.parentId = parentId
      self.config = config
    }
  }
}

// extensions

extension Parent.NotificationMethod {
  enum Config: Codable, Equatable, Sendable {
    case slack(channelId: String, channelName: String, token: String)
    case email(email: String)
    case text(phoneNumber: String)
  }
}
