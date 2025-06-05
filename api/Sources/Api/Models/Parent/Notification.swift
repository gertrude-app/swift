import DuetSQL
import Tagged

extension Parent {
  struct Notification: Codable, Sendable {
    var id: Id
    var parentId: Parent.Id
    var methodId: Parent.NotificationMethod.Id
    var trigger: Trigger
    var createdAt = Date()

    init(
      id: Id = .init(),
      parentId: Parent.Id,
      methodId: Parent.NotificationMethod.Id,
      trigger: Trigger
    ) {
      self.id = id
      self.parentId = parentId
      self.methodId = methodId
      self.trigger = trigger
    }
  }
}

// extensions

extension Parent.Notification {
  enum Trigger: String, Codable, CaseIterable, Equatable, Sendable {
    case unlockRequestSubmitted
    case suspendFilterRequestSubmitted
    case adminChildSecurityEvent
  }
}

// loaders

extension Parent.Notification {
  func method(in db: any DuetSQL.Client) async throws -> Parent.NotificationMethod {
    try await Parent.NotificationMethod.query()
      .where(.id == self.methodId)
      .first(in: db)
  }
}
