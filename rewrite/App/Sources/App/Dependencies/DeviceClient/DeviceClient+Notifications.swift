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
  func showBrowsersQuittingWarning() async {
    await showNotification(
      "⚠️ Web browsers quitting soon!",
      "Filter suspension ended. All browsers will quit in 60 seconds. Save any important work NOW."
    )
  }
}
