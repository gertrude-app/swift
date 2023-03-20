import Dependencies
import Foundation
import Models
import NetworkExtension

final class FilterManager: NSObject {
  @Dependency(\.system) var system

  var status: Status = .unknown
  var activationRequestCompleted = false

  func setup() async -> FilterState {
    print(
      "before load",
      system.filterProviderConfiguration() as Any,
      system.isNEFilterManagerSharedEnabled()
    )

    let loadResult = await system.loadFilterConfiguration()
    if case .failed(let err) = loadResult {
      status = .failedToLoadConfig(err)
      return .errorLoadingConfig
    }

    print(
      "after load",
      system.filterProviderConfiguration() as Any,
      system.isNEFilterManagerSharedEnabled()
    )

    // TODO: check enabled/config, add observer
    return .notInstalled
  }

  func installFilter() async throws -> FilterInstallResult {
    print("installFilter")
    guard system.isNEFilterManagerSharedEnabled() == false else {
      print("already installed")
      return .alreadyInstalled
    }

    // TODO: maybe remove this whole thing by checking what it resolves and
    // just hardcoding it
    guard let bundleIdentifier = system.extensionBundle().bundleIdentifier else {
      print("failed to get bundle identifier")
      return .failedToGetBundleIdentifier
    }

    print("requesting extension activation for \(bundleIdentifier)")
    system.requestExtensionActivation(bundleIdentifier, self)
    print("waiting for extension activation")

    // the user has to do several steps at this point, like allowing
    // installation of extension in security & privacy settings,
    // clicking the "allow" in the popup, so we wait for them

    // TODO: control time
    var waited = 0
    activationRequestCompleted = false
    while true {
      try await Task.sleep(nanoseconds: 1_000_000_000)
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
    print("configureFilter")
    guard system.isNEFilterManagerSharedEnabled() == false else {
      print("cf: already installed")
      return .alreadyInstalled
    }

    // check if there is an existing filter configuration
    let loadResult = await system.loadFilterConfiguration()
    if case .failed(let err) = loadResult {
      print("cf: failed to load config")
      return .failedToLoadConfig(err)
    }

    if system.filterProviderConfiguration() != nil {
      print("cf: has existing config")
      // log?  or maybe removeFromPreferences()?
    } else {
      print("cf: no existing config, updating")
      let providerConfiguration = NEFilterProviderConfiguration()
      providerConfiguration.filterSockets = true
      providerConfiguration.filterPackets = false
      let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "rofl bundle name"
      print("app name is \(appName)")
      system.updateNEFilterManagerShared(providerConfiguration, appName)
    }

    print("cf: enabling")
    system.enableNEFilterManagerShared()

    do {
      print("cf: saving")
      try await system.saveNEFilterManagerShared()
      print("cf: saved")
      return .installedSuccessfully
    } catch {
      print("cf: failed to save config", error)
      return .failedToSaveConfig(error)
    }
  }

  func filterState() -> FilterState {
    fatalError()
  }
}

// extensions, types

extension FilterManager {

  enum Status {
    case unknown
    case notInstalled
    case installedButNotRunning
    case running
    case failedToLoadConfig(Error)
  }
}
