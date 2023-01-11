struct AdminNotifier {
  var notify: (Admin.Id, AdminEvent) async throws -> Void
}

extension AdminNotifier {
  static var live: Self {
    .init(notify: notify(_:_:))
  }

  static var mock: Self {
    .init(notify: { _, _ in })
  }
}

private func notify(_ adminId: Admin.Id, _ event: AdminEvent) async throws {
  let admin = try await Current.db.find(adminId)
  let notifications = try await admin.notifications()
  for notification in notifications {
    switch (notification.trigger, event) {
    case (.suspendFilterRequestSubmitted, .suspendFilterRequestSubmitted(let event)):
      let method = try await notification.method()
      try await event.send(with: method.config)
    case (.unlockRequestSubmitted, .unlockRequestSubmitted(let event)):
      let method = try await notification.method()
      try await event.send(with: method.config)
    default:
      break
    }
  }
}
