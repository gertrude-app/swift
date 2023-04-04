import Combine
import Core
import Dependencies
import Foundation
import Models
import NetworkExtension

final class FilterManager: NSObject {
  private var cancellables = Set<AnyCancellable>()

  @Dependency(\.system) var system
  @Dependency(\.mainQueue) var scheduler

  func setup() async -> FilterState {
    system.filterDidChangePublisher().sink {
      filterStateChanges.withValue { subject in
        subject.send(self.getState())
      }
    }.store(in: &cancellables)

    return await loadState()
  }

  func loadState() async -> FilterState {
    let loadResult = await system.loadFilterConfiguration()
    if case .failed(let err) = loadResult {
      print("error loading config: \(err)")
      return .errorLoadingConfig
    }

    return getState()
  }

  // query current state, without loading filter configuration
  // loading filter configuration only needs to be done once, and is async
  private func getState() -> FilterState {
    if system.filterProviderConfiguration() == nil {
      return .notInstalled
    } else {
      return system.isNEFilterManagerSharedEnabled() ? .on : .off
    }
  }

  func startFilter() async -> FilterState {
    let state = await loadState()
    // TODO: maybe better options for some (non-.on) states, possible remediations?
    if state != .off {
      return state
    }

    system.enableNEFilterManagerShared()
    if let error = await system.saveNEFilterManagerShared() {
      print("error saving config: \(error)")
    }

    // now that we've attempted to stop the filter, recheck the state completely
    return await loadState()
  }

  func stopFilter() async -> FilterState {
    let state = await loadState()
    // TODO: maybe better options for some (non-.off) states, possible remediations?
    if state != .on {
      return state
    }

    system.disableNEFilterManagerShared()
    if let error = await system.saveNEFilterManagerShared() {
      print("error saving config: \(error)")
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
        // TODO: handle error
      } else if waited > 60 {
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
let filterStateChanges = Mutex(PassthroughSubject<FilterState, Never>())
