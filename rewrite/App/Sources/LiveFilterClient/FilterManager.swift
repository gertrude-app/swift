import Dependencies
import Foundation
import Models
import NetworkExtension

final class FilterManager: NSObject {
  @Dependency(\.system) var system

  var state: FilterState = .unknown
  var activationRequestCompleted = false

  func filterState() async -> FilterState {
    let loadResult = await system.loadFilterConfiguration()
    if case .failed(let err) = loadResult {
      print("error loading config: \(err)")
      state = .errorLoadingConfig
      return .errorLoadingConfig
    }

    if system.filterProviderConfiguration() == nil {
      return .notInstalled
    } else {
      return system.isNEFilterManagerSharedEnabled() ? .on : .off
    }
  }

  func setup() async -> FilterState {
    let state = await filterState()

    // TODO: check enabled/config, add observer

    return state
  }

  func startFilter() async -> FilterState {
    let state = await filterState()
    // TODO: maybe better options for some (non-.on) states, possible remediations?
    if state != .off {
      return state
    }

    system.enableNEFilterManagerShared()
    if let error = await system.saveNEFilterManagerShared() {
      print("error saving config: \(error)")
    }

    // now that we've attempted to stop the filter, recheck the state completely
    return await filterState()
  }

  func stopFilter() async -> FilterState {
    let state = await filterState()
    // TODO: maybe better options for some (non-.off) states, possible remediations?
    if state != .on {
      return state
    }

    system.disableNEFilterManagerShared()
    if let error = await system.saveNEFilterManagerShared() {
      print("error saving config: \(error)")
    }

    // now that we've attempted to stop the filter, recheck the state completely
    return await filterState()
  }

  func installFilter() async -> FilterInstallResult {
    print("installFilter")
    guard system.isNEFilterManagerSharedEnabled() == false else {
      print("already installed")
      return .alreadyInstalled
    }

    print("requesting extension activation")
    system.requestExtensionActivation(self)
    print("waiting for extension activation")

    // the user has to do several steps at this point, like allowing
    // installation of extension in security & privacy settings,
    // clicking the "allow" in the popup, so we wait for them

    // TODO: control time
    var waited = 0
    activationRequestCompleted = false
    while true {
      do {
        try await Task.sleep(nanoseconds: 1_000_000_000)
      } catch {}
      waited += 1
      if activationRequestCompleted {
        defer { activationRequestCompleted = false }
        return await configureFilter()
      } else if waited > 30 {
        return .timedOutWaiting
      }
    }
  }

  func configureFilter() async -> FilterInstallResult {
    guard system.isNEFilterManagerSharedEnabled() == false else {
      return .alreadyInstalled
    }

    // check if there is an existing filter configuration
    let loadResult = await system.loadFilterConfiguration()
    if case .failed(let err) = loadResult {
      return .failedToLoadConfig(err)
    }

    if system.filterProviderConfiguration() != nil {
      // log?  or maybe removeFromPreferences()?
    } else {
      let providerConfiguration = NEFilterProviderConfiguration()
      providerConfiguration.filterSockets = true
      providerConfiguration.filterPackets = false
      providerConfiguration
        .filterDataProviderBundleIdentifier = "com.netrivet.gertrude.filter-extension"
      system.updateNEFilterManagerShared(providerConfiguration)
    }

    system.enableNEFilterManagerShared()

    if let error = await system.saveNEFilterManagerShared() {
      return .failedToSaveConfig(error)
    } else {
      return .installedSuccessfully
    }
  }
}
