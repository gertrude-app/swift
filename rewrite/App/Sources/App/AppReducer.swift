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
    case loadedPersistentState(Persistent.State?)
  }

  @Dependency(\.filter) var filter
  @Dependency(\.storage) var storage

  var cancellables = Set<AnyCancellable>()

  var body: some ReducerOf<Self> {
    Reduce<State, Action> { state, action in
      switch action {
      case .delegate(.didFinishLaunching):
        return .merge(
          .run { [setup = filter.setup] send in
            await send(.filter(.receivedState(await setup())))
          },
          .run { [load = storage.loadPersistentState] send in
            await send(.loadedPersistentState(try load()))
          },
          .publisher {
            filter.changes().map { .filter(.receivedState($0)) }
          }
        )
      case .loadedPersistentState(let persistent):
        state.user = persistent?.user
        if state.user != nil {
          state.history.userConnection = .established(welcomeDismissed: true)
        }
        return .none
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
