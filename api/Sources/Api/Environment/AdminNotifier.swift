import Dependencies

struct AdminNotifier: Sendable {
  var notify: @Sendable (Parent.Id, AdminEvent) async -> Void
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
    .init { parentId, event in
      @Dependency(\.db) var db
      @Dependency(\.slack) var slack
      do {
        let parent = try await db.find(parentId)
        let notifications = try await parent.notifications(in: db)

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
                .error("failed to notify admin \(parentId) of event \(event): \(error)")
            }
          }

          // no notifications: send fallback email unless it's a security event
        } else {
          do {
            switch event {
            case .suspendFilterRequestSubmitted(let event):
              try await event.sendEmail(to: parent.email.rawValue, isFallback: true)
            case .unlockRequestSubmitted(let event):
              try await event.sendEmail(to: parent.email.rawValue, isFallback: true)
            case .adminChildSecurityEvent:
              break
            }
          } catch {
            await slack
              .error("failed to fallback email admin \(parentId) of event \(event): \(error)")
          }
        }

      } catch {
        await slack
          .error("failed to find admin \(parentId) data for event \(event): \(error)")
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
