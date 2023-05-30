import ClientInterfaces
import Combine
import Core
import Dependencies
import Foundation
import NetworkExtension

final class FilterManager: NSObject {
  private var cancellables = Set<AnyCancellable>()

  @Dependency(\.system) var system
  @Dependency(\.mainQueue) var scheduler

  func setup() async -> FilterExtensionState {
    system.filterDidChangePublisher().sink {
      filterStateChanges.withValue { subject in
        subject.send(self.getState())
      }
    }.store(in: &cancellables)

    return await loadState()
  }

  func loadState() async -> FilterExtensionState {
    let loadResult = await system.loadFilterConfiguration()
    if case .failed(let error) = loadResult {
      unexpectedError(id: "0738ecbd", error)
      return .errorLoadingConfig
    }

    return getState()
  }

  // query current state, without loading filter configuration
  // loading filter configuration only needs to be done once, and is async
  private func getState() -> FilterExtensionState {
    if system.filterProviderConfiguration() == nil {
      return .notInstalled
    } else {
      return system.isNEFilterManagerSharedEnabled()
        ? .installedAndRunning : .installedButNotRunning
    }
  }

  func startFilter() async -> FilterExtensionState {
    let state = await loadState()
    if state != .installedButNotRunning {
      // if happens moderately often, implement better behaviors for other states
      unexpectedError(id: "02ee5d90")
      return state
    }

    system.enableNEFilterManagerShared()

    if let error = await system.saveNEFilterManagerShared() {
      unexpectedError(id: "b787c1ff", error)
    }

    // now that we've attempted to stop the filter, recheck the state completely
    return await loadState()
  }

  func stopFilter() async -> FilterExtensionState {
    let state = await loadState()
    if state != .installedAndRunning {
      // if happens moderately often, implement better behaviors for other states
      unexpectedError(id: "6f5b0838")
      return state
    }

    system.disableNEFilterManagerShared()

    if let error = await system.saveNEFilterManagerShared() {
      unexpectedError(id: "214df4cf", error)
    }

    // now that we've attempted to stop the filter, recheck the state completely
    return await loadState()
  }

  func installFilter() async -> FilterInstallResult {
    guard system.isNEFilterManagerSharedEnabled() == false else {
      return .alreadyInstalled
    }

    system.requestExtensionActivation(self)

    // the user has to do several steps at this point, like allowing
    // installation of extension in security & privacy settings,
    // clicking the "allow" in the popup, so we wait for them

    await activationRequest.setValue(.pending)

    // TODO: this may not work at all... at least when RE-installing
    // the filter, it immediately moves to .suceeded, even if the
    // allow/deny filter content popup is sitting there on the screen
    // it MIGHT work on initial install, but i need to re-think this
    // to work in both scenarios. probably poll the filter state or
    // connection instead of checking the activation request itself
    // @see https://github.com/gertrude-app/project/issues/153
    var waited = 0
    while true {
      do {
        try await scheduler.sleep(for: .seconds(1))
      } catch {}
      waited += 1
      let requestStatus = await activationRequest.value
      if requestStatus == .succeeded {
        await activationRequest.setValue(.idle)
        return await configureFilter()
      } else if waited > 60 {
        return .timedOutWaiting
      }
    }
  }

  func replaceFilter() async -> FilterInstallResult {
    _ = await stopFilter()
    return await installFilter()
  }

  func uninstallFilter() async -> Bool {
    _ = await stopFilter()
    return await system.removeFilterConfiguration() == nil
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
      providerConfiguration.filterDataProviderBundleIdentifier = FILTER_EXT_BUNDLE_ID
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

let FILTER_EXT_BUNDLE_ID = "com.netrivet.gertrude.filter-extension"

enum ActivationRequestStatus {
  case idle, pending, failed, succeeded
}

let activationRequest = ActorIsolated<ActivationRequestStatus>(.idle)
let filterStateChanges = Mutex(PassthroughSubject<FilterExtensionState, Never>())
