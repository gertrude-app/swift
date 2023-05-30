import Dependencies
import SwiftUI

@Sendable func quitAllBrowsers() async {
  @Dependency(\.mainQueue) var mainQueue
  for app in NSWorkspace.shared.runningApplications {
    guard let appName = app.localizedName else { continue }
    if browserNames.contains(appName) {
      await terminate(app, on: mainQueue)
    }
  }
}

private func terminate(
  _ app: NSRunningApplication,
  on scheduler: AnySchedulerOf<DispatchQueue>
) async {
  app.forceTerminate()
  // checking termination status and "re"-terminating works around
  // loophole where an "unsaved changes" browser alert prevents termination
  try? await scheduler.sleep(for: .seconds(3))
  if !app.isTerminated {
    await terminate(app, on: scheduler)
  }
}

// TODO: should also test bundle identifiers,
// and should pull this periodically from the API
// so i can push hot-fixes to the list
// https://github.com/gertrude-app/project/issues/157
private let browserNames = [
  "Safari",
  "Google Chrome",
  "Google Chrome Beta",
  "Google Chrome Canary",
  "Firefox",
  "Firefox Nightly",
  "Firefox Developer Edition",
  "Chromium",
  "Opera",
  "Microsoft Edge",
  "Sizzy",
  "Vivaldi",
  "LockDown Browser",
  "Puffin",
  "Avast",
  "Avast Secure Browser",
]
