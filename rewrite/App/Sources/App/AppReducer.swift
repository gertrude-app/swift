import Combine
import ComposableArchitecture
import Core
import Foundation
import MacAppRoute
import Models

struct AppReducer: Reducer, Sendable {
  struct State: Equatable {
    var admin = AdminState()
    var app = AppState()
    var device = DeviceState()
    var filter = FilterFeature.State.unknown
    var history = HistoryFeature.State()
    var user: UserFeature.State?
  }

  enum Action: Equatable, Sendable {
    case application(ApplicationFeature.Action)
    case filter(FilterFeature.Action)
    case receivedXpcEvent(XPCEvent)
    case history(HistoryFeature.Action)
    case menuBar(MenuBarFeature.Action)
    case loadedPersistentState(Persistent.State?)
    case user(UserFeature.Action)
    case heartbeat(Heartbeat.Interval)
  }

  @Dependency(\.api) var api

  var body: some ReducerOf<Self> {
    Reduce<State, Action> { state, action in
      switch action {
      case .loadedPersistentState(let persistent):
        guard let user = persistent?.user else { return .none }
        state.user = user
        return .task {
          await api.setUserToken(user.token)
          return await .user(.refreshRules(
            result: TaskResult { try await api.refreshUserRules() },
            userInitiated: false
          ))
        }

      default:
        return .none
      }
    }

    // root reducers
    ApplicationFeature.RootReducer()
    HistoryFeature.RootReducer()
    MenuBarFeature.RootReducer()
    UserFeature.RootReducer()

    // feature reducers
    Scope(state: \.history, action: /Action.history) {
      HistoryFeature.Reducer()
    }
    Scope(state: \.filter, action: /Action.filter) {
      FilterFeature.Reducer()
    }
    Scope(state: \.menuBar, action: /Action.menuBar) {
      MenuBarFeature.Reducer()
    }
    .ifLet(\.user, action: /Action.user) {
      UserFeature.Reducer()
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
