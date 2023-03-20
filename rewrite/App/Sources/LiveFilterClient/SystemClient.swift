import Dependencies
import Foundation
import NetworkExtension
import SystemExtensions

struct SystemClient: Sendable {
  var extensionBundle: @Sendable () -> Bundle
  var loadFilterConfiguration: @Sendable () async -> LoadFilterConfigResult
  var isNEFilterManagerSharedEnabled: @Sendable () -> Bool
  var enableNEFilterManagerShared: @Sendable () -> Void
  var disableNEFilterManagerShared: @Sendable () -> Void
  var filterProviderConfiguration: @Sendable () -> NEFilterProviderConfiguration?
  var requestExtensionActivation: @Sendable (String, any OSSystemExtensionRequestDelegate) -> Void
  var updateNEFilterManagerShared: @Sendable (NEFilterProviderConfiguration, String) -> Void
  var saveNEFilterManagerShared: @Sendable () async throws -> Void
}

extension SystemClient: DependencyKey {
  static var liveValue: Self {
    let bundle = ThreadSafe(wrapped: getExtensionBundle())
    return .init(
      extensionBundle: { bundle.value },
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
      requestExtensionActivation: { bundleIdentifier, delegate in
        let activationRequest = OSSystemExtensionRequest.activationRequest(
          forExtensionWithIdentifier: bundleIdentifier,
          queue: .main
        )
        activationRequest.delegate = delegate
        OSSystemExtensionManager.shared.submitRequest(activationRequest)
      },
      updateNEFilterManagerShared: { configuration, appName in
        let manager = NEFilterManager.shared()
        manager.providerConfiguration = configuration
        manager.localizedDescription = appName
      },
      saveNEFilterManagerShared: { try await NEFilterManager.shared().saveToPreferences() }
    )
  }
}

extension SystemClient: TestDependencyKey {
  static let testValue = Self(
    extensionBundle: { Bundle.main },
    loadFilterConfiguration: { .doesNotExistOrLoadedSuccessfully },
    isNEFilterManagerSharedEnabled: { true },
    enableNEFilterManagerShared: {},
    disableNEFilterManagerShared: {},
    filterProviderConfiguration: { nil },
    requestExtensionActivation: { _, _ in },
    updateNEFilterManagerShared: { _, _ in },
    saveNEFilterManagerShared: {}
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
