import DuetSQL
import Tagged

final class AdminNotification: Codable {
  var id: Id
  var adminId: Admin.Id
  var methodId: AdminVerifiedNotificationMethod.Id
  var trigger: Trigger
  var createdAt = Date()

  var admin = Parent<Admin>.notLoaded
  var method = Parent<AdminVerifiedNotificationMethod>.notLoaded

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
  enum Trigger: String, Codable, CaseIterable, Equatable {
    case unlockRequestSubmitted
    case suspendFilterRequestSubmitted
    case adminChildSecurityEvent
  }
}

// loaders

extension AdminNotification {
  func method() async throws -> AdminVerifiedNotificationMethod {
    try await self.method.useLoaded(or: {
      try await Current.db.query(AdminVerifiedNotificationMethod.self)
        .where(.id == methodId)
        .first()
    })
  }
}
