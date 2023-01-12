import Foundation
import UserNotifications

class NotificationsPlugin: Plugin {
  let store: AppStore
  let center = UNUserNotificationCenter.current()

  var identifier: String { UUID().uuidString }

  init(store: AppStore) {
    self.store = store
    center.requestAuthorization(options: [.alert]) { _, _ in }
  }

  func respond(to event: AppEvent) {
    switch event {
    case .showNotification(title: let title, body: let body):
      log(.plugin("Notifications", .level(.info, "show notification", [
        "meta.primary": .string("title=\(title)\n\nbody=\(body)"),
      ])))
      let content = UNMutableNotificationContent()
      content.title = title
      content.body = body
      center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: nil))
    default:
      break
    }
  }
}
