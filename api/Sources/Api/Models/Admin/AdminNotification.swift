import DuetSQL
import Tagged

struct AdminNotification: Codable, Sendable {
  var id: Id
  var parentId: Admin.Id
  var methodId: AdminVerifiedNotificationMethod.Id
  var trigger: Trigger
  var createdAt = Date()

  init(
    id: Id = .init(),
    parentId: Admin.Id,
    methodId: AdminVerifiedNotificationMethod.Id,
    trigger: Trigger
  ) {
    self.id = id
    self.parentId = parentId
    self.methodId = methodId
    self.trigger = trigger
  }
}

// extensions

extension AdminNotification {
  enum Trigger: String, Codable, CaseIterable, Equatable, Sendable {
    case unlockRequestSubmitted
    case suspendFilterRequestSubmitted
    case adminChildSecurityEvent
  }
}

// loaders

extension AdminNotification {
  func method(in db: any DuetSQL.Client) async throws -> AdminVerifiedNotificationMethod {
    try await AdminVerifiedNotificationMethod.query()
      .where(.id == self.methodId)
      .first(in: db)
  }
}
