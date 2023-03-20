import Dependencies
import Foundation
import NetworkExtension
import SystemExtensions

struct SystemClient: Sendable {
  var loadFilterConfiguration: @Sendable () async -> LoadFilterConfigResult
  var isNEFilterManagerSharedEnabled: @Sendable () -> Bool
  var enableNEFilterManagerShared: @Sendable () -> Void
  var disableNEFilterManagerShared: @Sendable () -> Void
  var filterProviderConfiguration: @Sendable () -> NEFilterProviderConfiguration?
  var requestExtensionActivation: @Sendable (OSSystemExtensionRequestDelegate) -> Void
  var updateNEFilterManagerShared: @Sendable (NEFilterProviderConfiguration) -> Void
  var saveNEFilterManagerShared: @Sendable () async -> Error?
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
          // TODO: extract to a shared constant
          forExtensionWithIdentifier: "com.netrivet.gertrude.filter-extension",
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
    saveNEFilterManagerShared: { nil }
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

// implementations

private func getExtensionBundle() -> Bundle {
  let extensionsDirectoryURL = URL(
    fileURLWithPath: "Contents/Library/SystemExtensions",
    relativeTo: Bundle.main.bundleURL
  )
  let extensionURLs: [URL]
  do {
    extensionURLs = try FileManager.default.contentsOfDirectory(
      at: extensionsDirectoryURL,
      includingPropertiesForKeys: nil,
      options: .skipsHiddenFiles
    )
  } catch {
    fatalError(
      "Failed to get the contents of \(extensionsDirectoryURL.absoluteString): \(error.localizedDescription)"
    )
  }

  guard let extensionURL = extensionURLs.first else {
    fatalError("Failed to find any system extensions")
  }

  guard let extensionBundle = Bundle(url: extensionURL) else {
    fatalError("Failed to create a bundle with URL \(extensionURL.absoluteString)")
  }

  return extensionBundle
}
