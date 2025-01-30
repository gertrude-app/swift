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
      @Dependency(\.slack) var slack
      do {
        let admin = try await db.find(adminId)
        let notifications = try await admin.notifications(in: db)

        // happy path: they have at least one notification for this event
        if !notifications.isEmpty {
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
              await slack
                .sysLogErr("failed to notify admin \(adminId) of event \(event): \(error)")
            }
          }

          // no notifications: send fallback email unless it's a security event
        } else {
          do {
            switch event {
            case .suspendFilterRequestSubmitted(let event):
              try await event.sendEmail(to: admin.email.rawValue, isFallback: true)
            case .unlockRequestSubmitted(let event):
              try await event.sendEmail(to: admin.email.rawValue, isFallback: true)
            case .adminChildSecurityEvent:
              break
            }
          } catch {
            await slack
              .sysLogErr("failed to fallback email admin \(adminId) of event \(event): \(error)")
          }
        }

      } catch {
        await slack
          .sysLogErr("failed to find admin \(adminId) data for event \(event): \(error)")
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
