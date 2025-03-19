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
      true
    case .unknown, .errorLoadingConfig, .notInstalled:
      false
    }
  }

  public var isXpcReachable: Bool {
    switch self {
    // xpc is reachable in both these states (same as `installed`)
    case .installedAndRunning, .installedButNotRunning:
      true
    case .unknown, .errorLoadingConfig, .notInstalled:
      false
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
