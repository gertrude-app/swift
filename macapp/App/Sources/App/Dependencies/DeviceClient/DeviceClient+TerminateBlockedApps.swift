import AppKit
import Dependencies
import Gertie

@Sendable func terminateAllBlockedApps(_ apps: [BlockedApp]) async {
  @Dependency(\.mainQueue) var mainQueue
  for app in NSWorkspace.shared.runningApplications {
    if apps.blocks(app: app) {
      await terminate(app: app, retryDelay: .milliseconds(200), on: mainQueue)
    }
  }
}

@Sendable func terminateRunningApp(_ app: NSRunningApplication) async {
  @Dependency(\.mainQueue) var mainQueue
  await terminate(app: app, retryDelay: .milliseconds(200), on: mainQueue)
}

extension BlockedApp {
  func blocks(app: NSRunningApplication) -> Bool {
    app.runningApp.map(self.blocks(app:)) ?? false
  }
}

public extension Collection where Element == BlockedApp {
  func blocks(app: NSRunningApplication) -> Bool {
    self.contains { $0.blocks(app: app) }
  }
}
