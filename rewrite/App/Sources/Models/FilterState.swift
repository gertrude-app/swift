import Foundation

public enum FilterState: Equatable, Sendable {
  case unknown
  case errorLoadingConfig
  case notInstalled
  case off
  case on
  case suspended(resuming: Date)

  public var canReceiveMessages: Bool {
    switch self {
    case .on, .off, .suspended:
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
