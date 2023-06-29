import Combine
import Dependencies
import Foundation
import NetworkExtension
import SystemExtensions

struct SystemClient: Sendable {
  typealias Observer = (Notification) -> Void
  var loadFilterConfiguration: @Sendable () async -> LoadFilterConfigResult
  var isNEFilterManagerSharedEnabled: @Sendable () -> Bool
  var enableNEFilterManagerShared: @Sendable () -> Void
  var disableNEFilterManagerShared: @Sendable () -> Void
  var filterProviderConfiguration: @Sendable () -> NEFilterProviderConfiguration?
  var requestExtensionActivation: @Sendable (OSSystemExtensionRequestDelegate) -> Void
  var updateNEFilterManagerShared: @Sendable (NEFilterProviderConfiguration) -> Void
  var saveNEFilterManagerShared: @Sendable () async -> Error?
  var filterDidChangePublisher: @Sendable () -> AnyPublisher<Void, Never>
}

extension SystemClient: DependencyKey {
  static var liveValue: Self {
    .init(
      loadFilterConfiguration: {
        do {
          try await NEFilterManager.shared().loadFromPreferences()
          return .doesNotExistOrLoadedSuccessfully
        } catch {
          return .failed(error)
        }
      },
      isNEFilterManagerSharedEnabled: { NEFilterManager.shared().isEnabled },
      enableNEFilterManagerShared: { NEFilterManager.shared().isEnabled = true },
      disableNEFilterManagerShared: { NEFilterManager.shared().isEnabled = false },
      filterProviderConfiguration: { NEFilterManager.shared().providerConfiguration },
      requestExtensionActivation: { delegate in
        let activationRequest = OSSystemExtensionRequest.activationRequest(
          forExtensionWithIdentifier: FILTER_EXT_BUNDLE_ID,
          queue: .main
        )
        activationRequest.delegate = delegate
        OSSystemExtensionManager.shared.submitRequest(activationRequest)
      },
      updateNEFilterManagerShared: { configuration in
        let manager = NEFilterManager.shared()
        manager.providerConfiguration = configuration
        manager.localizedDescription = "Gertrude"
      },
      saveNEFilterManagerShared: {
        do {
          try await NEFilterManager.shared().saveToPreferences()
          return nil
        } catch {
          return error
        }
      },
      filterDidChangePublisher: {
        NotificationCenter.default.publisher(
          for: .NEFilterConfigurationDidChange,
          object: NEFilterManager.shared()
        ).map { _ in }.eraseToAnyPublisher()
      }
    )
  }
}

extension SystemClient: TestDependencyKey {
  static let testValue = Self(
    loadFilterConfiguration: { .doesNotExistOrLoadedSuccessfully },
    isNEFilterManagerSharedEnabled: { true },
    enableNEFilterManagerShared: {},
    disableNEFilterManagerShared: {},
    filterProviderConfiguration: { nil },
    requestExtensionActivation: { _ in },
    updateNEFilterManagerShared: { _ in },
    saveNEFilterManagerShared: { nil },
    filterDidChangePublisher: { Empty().eraseToAnyPublisher() }
  )
}

extension DependencyValues {
  var system: SystemClient {
    get { self[SystemClient.self] }
    set { self[SystemClient.self] = newValue }
  }
}

// types

enum LoadFilterConfigResult: Sendable {
  // Apple's API docs explicitly state that lack of an error means
  // "the configuration does not exist" ... "or is loaded successfully"
  case doesNotExistOrLoadedSuccessfully
  case failed(Error)
}
