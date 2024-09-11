import Dependencies

struct AdminNotifier: Sendable {
  var notify: @Sendable (Admin.Id, AdminEvent) async -> Void
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

@Sendable private func notify(adminId: Admin.Id, event: AdminEvent) async {
  // TODO: think about improving the perf of this by injecting a db
  @Dependency(\.db) var db
  do {
    let admin = try await db.find(adminId)
    let notifications = try await admin.notifications(in: db)
    for notification in notifications {
      do {
        switch (notification.trigger, event) {
        case (.suspendFilterRequestSubmitted, .suspendFilterRequestSubmitted(let event)):
          let method = try await notification.method(in: db)
          try await event.send(with: method.config)
        case (.unlockRequestSubmitted, .unlockRequestSubmitted(let event)):
          let method = try await notification.method(in: db)
          try await event.send(with: method.config)
        case (.adminChildSecurityEvent, .adminChildSecurityEvent(let event)):
          let method = try await notification.method(in: db)
          try await event.send(with: method.config)
        default:
          break
        }
      } catch {
        with(dependency: \.logger)
          .error("failed to notify admin \(adminId) of event \(event): \(error)")
      }
    }
  } catch {
    with(dependency: \.logger)
      .error("failed to find admin \(adminId) data for event \(event): \(error)")
  }
}
