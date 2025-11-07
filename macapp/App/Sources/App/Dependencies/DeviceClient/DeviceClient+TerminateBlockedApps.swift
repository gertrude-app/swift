import AppKit
import Dependencies
import Gertie

@Sendable func terminateAllBlockedApps(_ apps: [BlockedApp]) async {
  @Dependency(\.mainQueue) var mainQueue
  @Dependency(\.date) var date
  @Dependency(\.calendar) var calendar

  for app in NSWorkspace.shared.runningApplications {
    if apps.blocks(app: app, at: date.now, in: calendar) {
      await terminate(app: app, retryDelay: .milliseconds(200), on: mainQueue)
    }
  }
}

@Sendable func terminateRunningApp(_ app: RunningApp) async {
  @Dependency(\.mainQueue) var mainQueue
  if let nsRunningApp = app.nsRunningApplication {
    await terminate(app: nsRunningApp, retryDelay: .milliseconds(200), on: mainQueue)
  }
}

extension BlockedApp {
  func blocks(
    app: NSRunningApplication,
    at date: Date,
    in calendar: Calendar = .current,
  ) -> Bool {
    app.runningApp.map { self.blocks(app: $0, at: date, in: calendar) } ?? false
  }
}

public extension Collection<BlockedApp> {
  func blocks(
    app: NSRunningApplication,
    at date: Date,
    in calendar: Calendar = .current,
  ) -> Bool {
    self.contains { $0.blocks(app: app, at: date, in: calendar) }
  }
}
