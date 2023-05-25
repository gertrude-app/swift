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
}

public enum FilterInstallResult: Sendable {
  case alreadyInstalled
  case installedSuccessfully
  case userCancelled
  case timedOutWaiting
  case failedToGetBundleIdentifier
  case failedToLoadConfig(Error)
  case failedToSaveConfig(Error)
}
