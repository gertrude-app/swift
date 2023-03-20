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

  @Dependency(\.filter) var filter

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .delegate(.didFinishLaunching):
        Task {
          // TODO: this is a temporary testing shim
          let setupResult = await filter.setup()
          print("filter setup result", setupResult)
        }
        return .none
      default:
        return .none
      }
    }
    HistoryRoot()
  }
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
