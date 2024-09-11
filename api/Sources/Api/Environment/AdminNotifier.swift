import Dependencies

struct AdminNotifier: Sendable {
  var notify: @Sendable (Admin.Id, AdminEvent) async -> Void
}

// dependency

extension DependencyValues {
  var adminNotifier: AdminNotifier {
    get { self[AdminNotifier.self] }
    set { self[AdminNotifier.self] = newValue }
  }
}

extension AdminNotifier: DependencyKey {
  public static var liveValue: AdminNotifier {
    .init { adminId, event in
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
  }
}

#if DEBUG
  extension AdminNotifier: TestDependencyKey {
    public static var testValue: AdminNotifier {
      .init(notify: unimplemented("AdminNotifier.notify(adminId:event:)"))
    }
  }
#endif
