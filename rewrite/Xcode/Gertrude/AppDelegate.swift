import App
import AppKit
import Cocoa
import LiveApiClient
import NetworkExtension
import SystemExtensions

class AppDelegate: NSViewController, NSApplicationDelegate, NSWindowDelegate {
  let app = App()

  public func applicationDidFinishLaunching(_ notification: Notification) {
    app.send(delegate: .didFinishLaunching)
  }

  func startFilter() async {
    let filterAlreadyRunning = NEFilterManager.shared().isEnabled
    if filterAlreadyRunning {
      // registerWithProvider();
      return
    }

    guard let extensionIdentifier = extensionBundle().bundleIdentifier else {
      // status = .stopped
      return
    }

    // Start by activating the system extension
    let activationRequest = OSSystemExtensionRequest.activationRequest(
      forExtensionWithIdentifier: extensionIdentifier,
      queue: .main
    )
    activationRequest.delegate = self
    OSSystemExtensionManager.shared.submitRequest(activationRequest)
  }

  // main actor b/c simple firewall shows using DispatchQueue.main.async
  @MainActor
  func loadFilterConfiguration() async -> Bool {
    do {
      try await NEFilterManager.shared().loadFromPreferences()
      return true
    } catch {
      print("Failed to load the filter configuration: \(error.localizedDescription)")
      return false
    }
  }

  // main actor b/c simple firewall shows using DispatchQueue.main.async
  // specifically in non-async completion handler from `saveToPreferences`
  @MainActor
  func installFilter() async {
    let filterManager = NEFilterManager.shared()
    guard !filterManager.isEnabled else {
      print("filter already enabled, register instead")
      // registerWithProvider()
      return
    }

    let didLoadConfig = await loadFilterConfiguration()
    if didLoadConfig == false {
      // self.status = .error
      return
    }

    if filterManager.providerConfiguration == nil {
      print("creating filter provider configuration")
      let providerConfiguration = NEFilterProviderConfiguration()
      providerConfiguration.filterSockets = true
      providerConfiguration.filterPackets = false
      filterManager.providerConfiguration = providerConfiguration
      if let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String {
        filterManager.localizedDescription = appName
      }
    } else {
      print("filter provider configuration already exists")
    }

    filterManager.isEnabled = true

    do {
      try await filterManager.saveToPreferences()
      print("saved filter configuration")
      // registerWithProvider()
    } catch {
      print("Failed to save the filter configuration: \(error.localizedDescription)")
      // self.status = .error
    }
  }
}

// extension activation delegate
extension AppDelegate: OSSystemExtensionRequestDelegate {
  func request(
    _ request: OSSystemExtensionRequest,
    didFinishWithResult result: OSSystemExtensionRequest.Result
  ) {
    guard result == .completed else {
      print("system extension request finished not completed")
      // filterController.status = .error
      return
    }

    print("system extension request finished completed")
    Task { await self.installFilter() }
  }

  func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
    print("system extension request needs user approval")
  }

  func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
    print("system extension request failed w/ error: \(error)")
    // filterController.status = .error
  }

  func request(
    _ request: OSSystemExtensionRequest,
    actionForReplacingExtension existing: OSSystemExtensionProperties,
    withExtension extension: OSSystemExtensionProperties
  ) -> OSSystemExtensionRequest.ReplacementAction {
    let old = existing.bundleShortVersion
    let new = `extension`.bundleShortVersion
    print("system extension request replacing \(old) with \(new)")
    return .replace
  }
}

// TODO: this was a `lazy var`, maybe expensive?
func extensionBundle() -> Bundle {
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
