import App
import Core
import Dependencies
import Gertie
import Sparkle

extension UpdaterClient: DependencyKey {
  public static var liveValue: Self {
    UpdaterClient(
      triggerUpdate: { feedUrl in
        let updater = UpdateManager()
        retainer.replace(with: updater)
        try await updater.triggerUpdate(from: feedUrl)
      }
    )
  }
}

class UpdateManager {
  private var delegate: UpdaterDelegate
  private var updater: SPUUpdater

  @MainActor
  func triggerUpdate(from feedUrl: String) throws {
    delegate.feedUrl = feedUrl
    try updater.start()
    updater.checkForUpdates()
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

class UpdaterDelegate: NSObject, SPUUpdaterDelegate {
  var feedUrl: String?

  func feedURLString(for updater: SPUUpdater) -> String? {
    feedUrl
  }

  // @see https://sparkle-project.github.io/documentation/api-reference/Protocols/SPUUpdaterDelegate.html
  // for protocol delegate methods to respond to various events/errors
}

// sparkle is built on objective-c delegate patterns
// so we need to hold on to a reference to the current
// updater to keep all of the objects alive long enough
let retainer = Mutex(UpdateManager())
