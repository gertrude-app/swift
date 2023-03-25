import Combine
import ComposableArchitecture
import Foundation
import Models

struct AppReducer: Reducer, Sendable {
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

  @Dependency(\.storage) var storage
  @Dependency(\.filterXpc) var filterXpc
  @Dependency(\.filterExtension) var filterExtension

  var body: some ReducerOf<Self> {
    Reduce<State, Action> { state, action in
      switch action {

      case .delegate(.didFinishLaunching):
        return .merge(
          .run { send in
            await send(.filter(.receivedState(await filterExtension.setup())))
          },
          .run { send in
            await send(.loadedPersistentState(try storage.loadPersistentState()))
          },
          .publisher {
            // TODO: when filter goes _TO_ .notInstalled, the NSXPCConnection
            // becomes useless, we should re-create/invalidate it then
            filterExtension.stateChanges().map { .filter(.receivedState($0)) }
          }
        )

      case .loadedPersistentState(let persistent):
        state.user = persistent?.user
        if state.user != nil {
          state.history.userConnection = .established(welcomeDismissed: true)
        }
        return .none

      // TODO: test
      case .menuBar(.turnOnFilterClicked):
        if state.filter == .notInstalled {
          // TODO: handle install timout, error, etc
          return .fireAndForget { _ = await filterExtension.install() }
        } else {
          return .fireAndForget { _ = await filterExtension.start() }
        }

      // TODO: temporary
      case .menuBar(.suspendFilterClicked):
        return .fireAndForget { _ = await filterExtension.stop() }

      // TODO: temporary
      case .menuBar(.refreshRulesClicked):
        return .fireAndForget {
          print("connection healthy:", await filterXpc.isConnectionHealthy())
        }

      // TODO: temporary
      case .menuBar(.administrateClicked):
        return .fireAndForget {
          print("establish connection:", await filterXpc.establishConnection())
        }

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
