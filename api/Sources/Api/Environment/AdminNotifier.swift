struct AdminNotifier {
  var notify: (Admin.Id, AdminEvent) async -> Void
}

extension AdminNotifier {
  static var live: Self {
    // swiftformat:disable redundantSelf
    .init(notify: notify(adminId:event:))
  }

  static var mock: Self {
    .init(notify: { _, _ in })
  }
}

private func notify(adminId: Admin.Id, event: AdminEvent) async {
  do {
    let admin = try await Current.db.find(adminId)
    let notifications = try await admin.notifications()
    for notification in notifications {
      do {
        switch (notification.trigger, event) {
        case (.suspendFilterRequestSubmitted, .suspendFilterRequestSubmitted(let event)):
          let method = try await notification.method()
          try await event.send(with: method.config)
        case (.unlockRequestSubmitted, .unlockRequestSubmitted(let event)):
          let method = try await notification.method()
          try await event.send(with: method.config)
        case (.adminChildSecurityEvent, .adminChildSecurityEvent(let event)):
          let method = try await notification.method()
          try await event.send(with: method.config)
        default:
          break
        }
      } catch {
        Current.logger.error("failed to notify admin \(adminId) of event \(event): \(error)")
      }
    }
  } catch {
    Current.logger.error("failed to find admin \(adminId) data for event \(event): \(error)")
  }
}
