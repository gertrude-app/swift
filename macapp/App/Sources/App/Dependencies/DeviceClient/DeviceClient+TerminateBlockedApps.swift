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

extension BlockedApp {
  func blocks(app: NSRunningApplication) -> Bool {
    if let bundleId = app.bundleIdentifier,
       let displayName = app.localizedName {
      return self.blocks(bundleId: bundleId, displayName: displayName)
    }
    return false
  }
}

public extension Collection where Element == BlockedApp {
  func blocks(app: NSRunningApplication) -> Bool {
    self.contains { $0.blocks(app: app) }
  }
}
