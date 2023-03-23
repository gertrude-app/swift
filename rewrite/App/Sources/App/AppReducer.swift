import Combine
import ComposableArchitecture
import Foundation
import Models

struct AppReducer: Reducer {
  struct State: Equatable {
    var admin = AdminState()
    var app = AppState()
    var device = DeviceState()
    var filter = Filter.State.unknown
    var history = History.State()
    var user: User?
  }

  enum Action: Equatable, Sendable {
    case delegate(AppDelegate.Action)
    case filter(Filter.Action)
    case history(History.Action)
    case menuBar(MenuBar.Action)
  }

  @Dependency(\.filter) var filter

  var cancellables = Set<AnyCancellable>()

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .delegate(.didFinishLaunching):
        return .merge(
          .run { [setup = filter.setup] send in
            await send(.filter(.receivedState(await setup())))
          },
          .publisher {
            filter.changes().map { .filter(.receivedState($0)) }
          }
        )
      default:
        return .none
      }
    }
    HistoryRoot()
    Scope(state: \.filter, action: /Action.filter) {
      Filter()
    }
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
