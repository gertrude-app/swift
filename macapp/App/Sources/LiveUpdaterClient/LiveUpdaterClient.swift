import App
import Core
import Dependencies
import Gertie
import Sparkle

extension UpdaterClient: DependencyKey {
  public static var liveValue: Self {
    let updater = UpdateManager()
    manager.replace(with: updater)
    return UpdaterClient(
      triggerUpdate: { feedUrl in
        // in the (very unlikely) event of a data-race here
        // the racing thread will just get a dummy updater
        let updater = manager.replace(with: NoopManager())
        defer { manager.replace(with: updater) }

        if !updater.windowOpen {
          try await updater.triggerUpdate(from: feedUrl)
        }
      }
    )
  }
}

private class UpdateManager: Manager {
  private var delegate: UpdaterDelegate
  private var updater: SPUUpdater

  @MainActor
  func triggerUpdate(from feedUrl: String) async throws {
    delegate.feedUrl = feedUrl
    try updater.start()
    updater.checkForUpdates()
  }

  var windowOpen: Bool {
    updater.sessionInProgress
  }

  init() {
    delegate = UpdaterDelegate()
    updater = SPUUpdater(
      hostBundle: Bundle.main,
      applicationBundle: Bundle.main,
      // NB: i could probably provide my own driver (or nil?) here if i wanted
      // to bypass the normal Sparkle UI -- it's a bit lame that users have to click
      // to update in the Sparkle popup after they already clicked our UI to update
      // however, their UI does cover a lot of edge cases, like failure to download...
      userDriver: SPUStandardUserDriver(hostBundle: Bundle.main, delegate: nil),
      delegate: delegate
    )
  }
}

// @see https://sparkle-project.github.io/documentation/api-reference/Protocols/SPUUpdaterDelegate.html
// for protocol delegate methods to respond to various events/errors
private class UpdaterDelegate: NSObject, SPUUpdaterDelegate {
  var feedUrl: String?

  func feedURLString(for updater: SPUUpdater) -> String? {
    feedUrl
  }
}

private protocol Manager {
  func triggerUpdate(from feedUrl: String) async throws
  var windowOpen: Bool { get }
}

private struct NoopManager: Manager {
  func triggerUpdate(from feedUrl: String) async throws {}
  var windowOpen: Bool { true }
}

private let manager: Mutex<any Manager> = Mutex(NoopManager())
