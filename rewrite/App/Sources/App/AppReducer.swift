import ComposableArchitecture
import Foundation
import Models

struct AppReducer: Reducer {
  struct State: Equatable {
    var admin = AdminState()
    var app = AppState()
    var device = DeviceState()
    var filter = FilterState.unknown
    var history = History.State()
    var user: User?
  }

  enum Action: Equatable, Sendable {
    case delegate(AppDelegateReducer.Action)
    case history(History.Action)
    case menuBar(MenuBar.Action)
  }

  var body: some ReducerOf<Self> {
    HistoryRoot()
  }
}

enum FilterState: Equatable {
  case unknown
  case notInstalled
  case off
  case on
  case suspended(resuming: Date)
}

struct AppState: Equatable {
  var version = "(unknown)"
  var updateChannel = "release" // TODO: enum
  var menuBarDropdownVisible = false
}

struct DeviceState: Equatable {
  var colorScheme = "light" // TODO: enum
  var hasInternetConnection = false
}

struct AdminState: Equatable {
  var accountStatus = "active" // TODO: enum
}
