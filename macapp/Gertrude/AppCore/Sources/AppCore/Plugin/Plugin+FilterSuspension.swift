import Foundation
import Shared
import SharedCore
import SwiftUI

class FilterSuspensionPlugin: NSObject, WindowPlugin {
  var store: AppStore
  var windowOpen = false
  var window: NSWindow?
  var title = "Gertrude"
  var currentSuspension: FilterSuspension?
  var timer: Timer?

  var initialDims: (width: CGFloat, height: CGFloat) {
    (width: FilterSuspensionRequest.MIN_WIDTH, height: FilterSuspensionRequest.MIN_HEIGHT)
  }

  var contentView: NSView {
    NSHostingView(rootView: FilterSuspensionRequest().environmentObject(store))
  }

  init(store: AppStore) {
    self.store = store
    super.init()
    pollSuspension()
  }

  func respond(to event: AppEvent) {
    switch event {
    case .requestSuspendFilterWindowOpened:
      openWindow()
    case .suspendFilter(let suspension):
      SendToFilter.suspension(suspension)
      currentSuspension = suspension
    case .cancelFilterSuspension:
      Task { await quitBrowsersIn60Seconds() }
      SendToFilter.cancelSuspension()
      currentSuspension = nil
    default:
      break
    }
  }

  // this is crude, and wastes some cpu cycles, but should be effective
  // in guarding against early, incorrect expiration for long suspensions,
  // and cover the problem where the computer is asleep for some/all of
  // the suspension duration. long-term, when the app is rewritten, probably
  // a better approach should be found
  func pollSuspension() {
    timer = Timer.repeating(every: .seconds(10)) { [weak self] _ in
      guard let self = self, let suspension = self.currentSuspension else {
        return
      }
      let remaining = Date().distance(to: suspension.expiresAt)
      if remaining < 5 {
        Task { await self.quitBrowsersIn60Seconds() }
        SendToFilter.cancelSuspension()
        self.currentSuspension = nil
      }
    }
  }

  @MainActor
  func quitBrowsersIn60Seconds() {
    let title = "⚠️ Web browsers quitting soon!"
    let body =
      "Filter suspension ended. All browsers will quit in 60 seconds. Save any important work NOW."
    store.send(.emitAppEvent(.showNotification(title: title, body: body)))

    // @TODO: should also test bundle identifiers, and should pull this periodically from the API
    // so i can push hot-fixes to the list
    let browserNames = [
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

    afterDelayOf(seconds: 60) {
      for app in NSWorkspace.shared.runningApplications {
        guard let appName = app.localizedName else { return }
        if browserNames.contains(appName) || !isDev() && appName == "Brave Browser" {
          terminate(app: app)
        }
      }
    }
  }

  func windowWillClose(_ notification: Notification) {
    store.send(.requestFilterSuspensionWindowClosed)
    windowOpen = false
  }
}

// helpers

private func terminate(app: NSRunningApplication) {
  log(.plugin("FilterSuspension", .info("quitting browser \(app.localizedName ?? "")")))
  app.forceTerminate()

  // checking termination status and "re"-terminating works around
  // loophole where an "unsaved changes" browser alert prevents termination
  afterDelayOf(seconds: 5) {
    if !app.isTerminated {
      log(.plugin("FilterSuspension", .info("re-quitting browser \(app.localizedName ?? "")")))
      terminate(app: app)
    }
  }
}
