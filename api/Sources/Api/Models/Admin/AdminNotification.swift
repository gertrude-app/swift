import DuetSQL
import Tagged

struct AdminNotification: Codable, Sendable {
  var id: Id
  var adminId: Admin.Id
  var methodId: AdminVerifiedNotificationMethod.Id
  var trigger: Trigger
  var createdAt = Date()

  init(
    id: Id = .init(),
    adminId: Admin.Id,
    methodId: AdminVerifiedNotificationMethod.Id,
    trigger: Trigger
  ) {
    self.id = id
    self.adminId = adminId
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
  func method() async throws -> AdminVerifiedNotificationMethod {
    try await AdminVerifiedNotificationMethod.query()
      .where(.id == self.methodId)
      .first()
  }
}
