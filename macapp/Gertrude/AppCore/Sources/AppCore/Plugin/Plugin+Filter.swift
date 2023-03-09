import Foundation
import Shared
import SharedCore
import XCore

class FilterPlugin: StorePlugin {
  let store: AppStore

  init(store: AppStore) {
    self.store = store
    FilterController.shared.statusChangeSubscriber = { newStatus in
      store.send(.setFilterStatus(newStatus))
    }
    FilterController.shared.load()
    triggerRefreshRulesRequest()
    checkForAutoUpdates()
  }

  func checkForAutoUpdates() {
    let current = Current.appVersion
    let last = Current.deviceStorage.get(.installedAppVersion)
    Current.deviceStorage.set(.installedAppVersion, current)

    // delay is so we can check the filter status, it starts unknown
    // and takes a fews milliseconds to become known
    afterDelayOf(seconds: 5) { [weak self] in
      let status = self?.store.state.filterStatus
      log(.plugin("Filter", .level(.notice, "post-launch check for filter replace", [
        "meta.primary": .string("last: \(~last), current: \(current), filter: \(~status)"),
      ])))

      if let last = last, last != current, self?.store.state.filterState != .off {
        log(.plugin("Filter", .level(.notice, "replacing filter", [
          "meta.primary": .string("\(last) -> \(current)"),
        ])))
        FilterController.shared.replace()
      }
    }
  }

  func respond(to event: AppEvent) {
    switch event {
    case .startFilter:
      FilterController.shared.start()
      triggerRefreshRulesRequest()
    case .stopFilter:
      FilterController.shared.stop()
    case .removeFilter:
      FilterController.shared.remove()
    case .receivedRefreshRulesData(
      data: let data,
      notify: let notify
    ):
      handleRefreshRulesData(data, notify)
    default:
      break
    }
  }

  func triggerRefreshRulesRequest() {
    // wait a bit to ensure XPC connection is ready, then request rule refresh
    // long-term, might be better to monitor the state of the XPC connection
    // and make this request as soon as it is setup, but this is simple, and should work
    afterDelayOf(seconds: 2.0) { [weak self] in
      guard let self = self, self.store.state.hasUserToken else { return }
      self.store.send(.appLaunchRefreshRuleEntities)
    }
  }

  func handleRefreshRulesData(_ data: ApiClient.RefreshRulesData, _ notify: Bool) {
    App.shared.appDescriptorFactory = AppDescriptorFactory(appIdManifest: data.idManifest)

    store.send(.setKeylogging(enabled: data.keyLoggingEnabled))
    store.send(.setScreenshots(
      enabled: data.screenshotsEnabled,
      size: data.screenshotsResolution,
      frequency: data.screenshotsFrequency
    ))

    guard let manifestData = try? JSON.data(data.idManifest) else {
      log(.encodeError(AppIdManifest.self))
      return
    }

    let keysData = data.keys.compactMap { try? JSON.data($0) }
    guard keysData.count == data.keys.count else {
      log(.encodeCountError(FilterKey.self, expected: data.keys.count, actual: keysData.count))
      return
    }

    SendToFilter.refreshedRulesData(
      keys: keysData,
      idManifest: manifestData
    ) { [weak self] success in
      guard notify else { return }
      DispatchQueue.main.async { [weak self] in
        guard success else {
          let title = "Error refreshing rules"
          let body = "Please try again, or have an admin examine the logs for more info."
          self?.store.send(.emitAppEvent(.showNotification(title: title, body: body)))
          log(.plugin("Filter", .error("error sending refreshed rules to filter", nil)))
          return
        }
        self?.store
          .send(.emitAppEvent(.showNotification(title: "Rules refreshed successfully", body: "")))
        log(.plugin("Filter", .info("successfully sent refreshed rules to filter")))
      }
    }
  }

  func onTerminate() {
    FilterController.shared.unload()
  }
}
