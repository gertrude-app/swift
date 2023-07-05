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
    switch await loadState() {
    case .installedAndRunning, .installedButNotRunning:
      return .alreadyInstalled
    case .errorLoadingConfig, .notInstalled, .unknown:
      break
    }

    guard system.isNEFilterManagerSharedEnabled() == false else {
      return .alreadyInstalled
    }

    system.requestExtensionActivation(self)

    // the delegate os system extension request almost always succeeds immediately
    // it's result has nothing to do with whether the user clicks "allow", etc.
    await activationRequest.setValue(.waitingForDelegateRequest)

    var waited = 0
    var configureTask: Task<Void, Never>?

    while true {

      try? await scheduler.sleep(for: .seconds(1))
      waited += 1

      switch await activationRequest.value {

      // the user has to do several steps at this point, like allowing
      // installation of extension in security & privacy settings,
      // clicking the "allow" in the popup, so we wait for them
      case .delegateRequestSucceeded:
        await activationRequest.setValue(.configuring)
        configureTask = Task { [system] in await configureFilter(system) }

      // should be extremely rare, we log unexpected errors in the delegate
      case .delegateRequestFailed(let error):
        await activationRequest.setValue(.idle)
        return .activationRequestFailed(error)

      // we got some kind of completion, we know what happened to the install request
      case .complete(let result):
        await activationRequest.setValue(.idle)
        return result

      // no resolution after 90 seconds, user probably confused, missed a step
      case .idle, .configuring, .waitingForDelegateRequest:
        if waited > 90 {
          configureTask?.cancel()
          await activationRequest.setValue(.idle)
          return .timedOutWaiting
        }
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
}

@Sendable func configureFilter(_ system: SystemClient) async {
  guard system.isNEFilterManagerSharedEnabled() == false else {
    await activationRequest.setValue(.complete(.alreadyInstalled))
    return
  }

  // check if there is an existing filter configuration
  let loadResult = await system.loadFilterConfiguration()
  if case .failed(let err) = loadResult {
    await activationRequest.setValue(.complete(.failedToLoadConfig(err)))
    return
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

  // this is the suspension point where we spend the most time, while we wait
  // for the user to click "allow", and (i think) accept security & privacy
  if let error = await system.saveNEFilterManagerShared() {
    // if the user clicks "don't allow" the error is "permission denied"
    let result = error.localizedDescription == "permission denied"
      ? FilterInstallResult.userClickedDontAllow : .failedToSaveConfig(error)
    await activationRequest.setValue(.complete(result))
  } else {
    await activationRequest.setValue(.complete(.installedSuccessfully))
  }
}

enum ActivationRequestStatus {
  case idle
  case waitingForDelegateRequest
  case delegateRequestFailed(Error?)
  case delegateRequestSucceeded
  case configuring
  case complete(FilterInstallResult)
}

let activationRequest = ActorIsolated<ActivationRequestStatus>(.idle)
let filterStateChanges = Mutex(PassthroughSubject<FilterExtensionState, Never>())

let FILTER_EXT_BUNDLE_ID = "com.netrivet.gertrude.filter-extension"
