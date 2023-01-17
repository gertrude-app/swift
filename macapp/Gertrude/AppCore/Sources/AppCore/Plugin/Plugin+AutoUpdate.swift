import Foundation
import Shared
import SharedCore
import Sparkle

class AutoUpdatePlugin: NSObject, Plugin, SPUUpdaterDelegate {
  var store: AppStore
  var updaterController: SPUStandardUpdaterController?
  var backgroundTimer: Timer?

  enum ForcedUpdateType {
    case currentChannelLatest
    case specificVersion(String)
  }

  var forcedUpdate: ForcedUpdateType?

  init(store: AppStore) {
    self.store = store
    super.init()

    updaterController = SPUStandardUpdaterController(
      startingUpdater: true,
      updaterDelegate: self,
      userDriverDelegate: nil
    )

    // gertie almost never restarts, and Sparkle won't check for updates
    // on the _first_ app "launch", so we'll check manually every 6 hours
    // to ensure we are always prompting for updates
    backgroundTimer = Timer.repeating(every: .hours(6)) { [weak self] _ in
      self?.updaterController?.updater.checkForUpdatesInBackground()
    }

    afterDelayOf(seconds: 15) { [weak self] in
      log(.plugin("AutoUpdate", .info("post-launch check filter restart failsafe")))
      guard !isDev(),
            store.state.filterState != .on,
            let restartTime = self?.filterRestartFailsafe,
            Date() < restartTime.addingTimeInterval(.minutes(3))
      else {
        return
      }

      log(.plugin("AutoUpdate", .error("restart failure detected, restarting", nil)))
      store.send(.startFilter)
    }
  }

  func respond(to event: AppEvent) {
    switch event {
    case .forceAppUpdate:
      forcedUpdate = .currentChannelLatest
      updaterController?.checkForUpdates(nil)
    case .requestCheckForUpdates:
      updaterController?.checkForUpdates(nil)
    case .requestLatestAppVersion:
      updaterController?.updater.checkForUpdateInformation()
    case .forceAutoUpdateToVersion(let version):
      forcedUpdate = .specificVersion(version)
    default:
      break
    }
  }

  func updater(_: SPUUpdater, willInstallUpdate _: SUAppcastItem) {
    if store.state.filterState == .on {
      log(.plugin("AutoUpdate", .notice("about to update, setting filter restart failsafe")))
      filterRestartFailsafe = Date()
    }
    if forcedUpdate != nil {
      log(.plugin("AutoUpdate", .notice("spoofing old version for forced filter auto-update")))
      Current.deviceStorage.set(.installedAppVersion, "0.0.000001")
    }
  }

  func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
    log(.plugin("AutoUpdate", .info("\(#function) called")))
    store.send(.healthCheck(.setString(\.latestAppVersion, item.versionString)))
  }

  func updaterDidNotFindUpdate(_ updater: SPUUpdater, error: Error) {
    log(.plugin("AutoUpdate", .info("\(#function) called")))
    store.send(.healthCheck(.setString(\.latestAppVersion, Current.appVersion)))
  }

  func feedURLString(for updater: SPUUpdater) -> String? {
    if let custom = Current.deviceStorage.getURL(.appcastEndpointOverride) {
      log(.plugin("AutoUpdate", .level(.notice, "custom appcast feed url", .primary("\(custom)"))))
      return custom.absoluteString
    }

    var query = AppcastQuery(channel: nil, force: false, version: nil)
    switch forcedUpdate {
    case .none:
      query.channel = store.state.autoUpdateReleaseChannel
    case .some(.currentChannelLatest):
      query.channel = store.state.autoUpdateReleaseChannel
      query.force = true
    case .some(.specificVersion(let version)):
      query.force = true
      query.version = version
    }

    let endpoint = isDev() ? "http://127.0.0.1:8080" : "https://api.gertrude.app"
    let urlString = "\(endpoint)/appcast.xml\(query.urlString)"
    log(.plugin("AutoUpdate", .level(.info, "set appcast feed url", .primary(urlString))))
    return urlString
  }

  var filterRestartFailsafe: Date? {
    set {
      if let date = newValue {
        Current.deviceStorage.setDate(.filterRestartFailsafe, date)
      } else {
        Current.deviceStorage.delete(.filterRestartFailsafe)
      }
    }
    get {
      defer { Current.deviceStorage.delete(.filterRestartFailsafe) }
      return Current.deviceStorage.getDate(.filterRestartFailsafe)
    }
  }
}
