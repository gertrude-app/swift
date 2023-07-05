import Foundation
import Gertie

public enum FilterExtensionState: Equatable, Sendable {
  case unknown
  case errorLoadingConfig
  case notInstalled
  case installedButNotRunning
  case installedAndRunning

  public var installed: Bool {
    switch self {
    case .installedAndRunning, .installedButNotRunning:
      return true
    case .unknown, .errorLoadingConfig, .notInstalled:
      return false
    }
  }

  public var isXpcReachable: Bool {
    switch self {
    // xpc is reachable in both these states (same as `installed`)
    case .installedAndRunning, .installedButNotRunning:
      return true
    case .unknown, .errorLoadingConfig, .notInstalled:
      return false
    }
  }
}

public enum FilterInstallResult: Sendable {
  case activationRequestFailed(Error?)
  case alreadyInstalled
  case installedSuccessfully
  case userClickedDontAllow
  case timedOutWaiting
  case failedToGetBundleIdentifier
  case failedToLoadConfig(Error)
  case failedToSaveConfig(Error)
}
