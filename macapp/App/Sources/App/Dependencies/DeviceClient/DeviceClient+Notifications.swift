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

@Sendable func requestNotificationAuth() async {
  {
    // sync closure to avoid warning about preferring async version
    UNUserNotificationCenter
      .current()
      .requestAuthorization(options: [.alert]) { _, _ in }
  }()
}

extension DeviceClient {
  func notifyNoInternet() async {
    await showNotification(
      "⚠️ No internet connection",
      "Please connect to the internet and try again."
    )
  }

  func notifyBrowsersQuitting() async {
    await showNotification(
      "⚠️ Web browsers quitting soon!",
      "Filter suspension ended. All browsers will quit in 60 seconds. Save any important work NOW."
    )
  }

  func notifyUnexpectedError() async {
    await showNotification(
      "⚠️ Unexpected error",
      "Sorry, please try again, or contact Gertrude support if the problem persists."
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
      body = "Filter will resume normal blocking \(resuming)"
    }
    await showNotification(title, body)
  }
}
