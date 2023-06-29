import TaggedTime
import UserNotifications

@Sendable func showNotification(title: String, body: String) {
  let content = UNMutableNotificationContent()
  content.title = title
  content.body = body
  UNUserNotificationCenter.current().add(UNNotificationRequest(
    identifier: UUID().uuidString,
    content: content,
    trigger: nil
  ))
}

@Sendable func getNotificationsSetting() async -> NotificationsSetting {
  await withCheckedContinuation { continuation in
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      if settings.authorizationStatus != .authorized || settings.alertStyle == .none {
        continuation.resume(returning: .none)
      } else if settings.alertStyle == .banner {
        continuation.resume(returning: .banner)
      } else {
        continuation.resume(returning: .alert)
      }
    }
  }
}

extension DeviceClient {
  func notifyBrowsersQuitting() async {
    await showNotification(
      "⚠️ Web browsers quitting soon!",
      "Filter suspension ended. All browsers will quit in 60 seconds. Save any important work NOW."
    )
  }

  func notifyFilterSuspensionDenied(with comment: String?) async {
    await showNotification(
      "⛔️ Suspend filter request DENIED",
      comment == nil ? "" : "Parent comment: \"\(comment ?? "")\""
    )
  }

  func notifyUnlockRequestUpdated(accepted: Bool, target: String, comment: String?) async {
    let title = "\(accepted ? "🔓" : "🔒") Unlock request \(accepted ? "ACCEPTED" : "REJECTED")"
    var body = "Requested address: \(target)"
    if let comment, !comment.isEmpty {
      body += "\nParent comment: \"\(comment)\""
    }
    await showNotification(title, body)
  }

  func notifyFilterSuspension(
    resuming seconds: Seconds<Int>,
    from now: Date = Date(),
    with comment: String?
  ) async {
    let title = "🟠 Temporarily disabling filter"
    let resuming = now.timeRemaining(until: now.advanced(by: .init(seconds.rawValue))) ?? "soo"
    let body: String
    if let comment, !comment.isEmpty {
      body = "Parent comment: \"\(comment)\"\nFilter suspended, resuming \(resuming)"
    } else {
      body = "Filter will resume normal blocking in \(resuming)"
    }
    await showNotification(title, body)
  }
}
