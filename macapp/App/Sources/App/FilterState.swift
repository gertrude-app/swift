import Core
import Dependencies
import Foundation
import Gertie

enum FilterState: Equatable, Codable {
  case off
  case on
  case suspended(resuming: String)

  var isSuspended: Bool {
    switch self {
    case .suspended:
      return true
    case .off, .on:
      return false
    }
  }
}

extension FilterState {
  var userFilterState: UserFilterState {
    switch self {
    case .off:
      return .off
    case .on:
      return .on
    case .suspended:
      return .suspended
    }
  }

  init(_ rootState: AppReducer.State) {
    self.init(
      extensionState: rootState.filter.extension,
      currentSuspensionExpiration: rootState.filter.currentSuspensionExpiration
    )
  }

  init(extensionState: FilterExtensionState, currentSuspensionExpiration: Date?) {
    switch extensionState {
    case .unknown,
         .errorLoadingConfig,
         .notInstalled,
         .installedButNotRunning:
      self = .off
    case .installedAndRunning:
      @Dependency(\.date.now) var now
      guard let expiration = currentSuspensionExpiration,
            expiration > now else {
        self = .on
        return
      }
      self = .suspended(resuming: now.timeRemaining(until: expiration) ?? "now")
    }
  }
}

extension UserFilterState {
  init(_ rootState: AppReducer.State) {
    self = FilterState(rootState).userFilterState
  }

  init(extensionState: FilterExtensionState, currentSuspensionExpiration: Date?) {
    self = FilterState(
      extensionState: extensionState,
      currentSuspensionExpiration: currentSuspensionExpiration
    ).userFilterState
  }
}
