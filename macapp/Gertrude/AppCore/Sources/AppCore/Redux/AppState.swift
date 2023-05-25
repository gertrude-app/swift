import Foundation
import Gertie
import SharedCore
import SwiftUI

class AppState {
  var userToken: UUID? = Current.deviceStorage.getUUID(.userToken)
  var autoUpdateReleaseChannel = ReleaseChannel.stable
  var filterStatus = FilterStatus.unknown
  var filterSuspension: FilterSuspension?
  var colorScheme = ColorScheme.light
  var adminWindow = AdminWindowState.default
  var requestsWindow = RequestsWindowState()
  var requestFilterSuspensionWindow = RequestFilterSuspensionWindowState()
  var loggingWindow = LoggingWindow()
  var logging = Logging()
  var monitoring = MonitoringState()
  var accountStatus = AdminAccountStatus.active
}

extension AppState {
  var filterState: FilterState {
    if filterStatus != .installedAndRunning {
      return .off
    }
    return filterSuspension?.isActive == true ? .suspended : .on
  }

  var hasUserToken: Bool {
    userToken != nil
  }
}

enum FetchState<T>: Equatable {
  static func == (lhs: FetchState<T>, rhs: FetchState<T>) -> Bool {
    switch (lhs, rhs) {
    case (.waiting, .waiting):
      return true
    case (.fetching, .fetching):
      return true
    default:
      return false
    }
  }

  enum Action: Equatable {
    static func == (lhs: FetchState<T>.Action, rhs: FetchState<T>.Action) -> Bool {
      switch (lhs, rhs) {
      case (.setWaiting, .setWaiting):
        return true
      case (.setFetching, .setFetching):
        return true
      default:
        return false
      }
    }

    case setWaiting
    case setFetching
    case setSuccess(T)
    case setError(String)
  }

  case waiting
  case fetching
  case success(T)
  case error(String)

  func respond(to action: Action) -> FetchState<T> {
    switch (self, action) {
    case (.waiting, .setFetching):
      return .fetching
    case (.fetching, .setSuccess(let value)):
      return .success(value)
    case (.fetching, .setError(let error)):
      return .error(error)
    case (.success, .setWaiting):
      return .waiting
    case (.error, .setWaiting):
      return .waiting
    default:
      return self // all other transitions are illegal
    }
  }

  var isFetching: Bool {
    switch self {
    case .fetching:
      return true
    default:
      return false
    }
  }

  var isSubmitted: Bool {
    switch self {
    case .error, .success:
      return true
    default:
      return false
    }
  }

  var errorMessage: String? {
    switch self {
    case .error(let error):
      return error
    default:
      return nil
    }
  }
}
