import Combine
import ComposableArchitecture
import Core
import Foundation
import MacAppRoute
import Models
import Shared

struct AppReducer: Reducer, Sendable {
  struct State: Equatable {
    var admin = AdminFeature.State()
    var adminWindow = AdminWindowFeature.State()
    var appUpdates = AppUpdatesFeature.State()
    var device = DeviceState()
    var filter = FilterFeature.State.unknown
    var history = HistoryFeature.State()
    var user: UserFeature.State?
    var blockedRequests = BlockedRequestsFeature.State()
  }

  enum Action: Equatable, Sendable {
    case admin(AdminFeature.Action)
    case adminWindow(AdminWindowFeature.Action)
    case application(ApplicationFeature.Action)
    case appUpdates(AppUpdatesFeature.Action)
    case filter(FilterFeature.Action)
    case xpc(XPCEvent.App)
    case history(HistoryFeature.Action)
    case menuBar(MenuBarFeature.Action)
    case loadedPersistentState(Persistent.State?)
    case user(UserFeature.Action)
    case heartbeat(Heartbeat.Interval)
    case blockedRequests(BlockedRequestsFeature.Action)

    indirect case adminAuthenticated(Action)
  }

  @Dependency(\.api) var api

  var body: some ReducerOf<Self> {
    Reduce<State, Action> { state, action in
      switch action {
      case .loadedPersistentState(let persistent):
        guard let user = persistent?.user else { return .none }
        state.user = user
        return .run { send in
          await api.setUserToken(user.token)
          return await send(.user(.refreshRules(
            result: TaskResult { try await api.refreshUserRules() },
            userInitiated: false
          )))
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
    BlockedRequestsFeature.RootReducer()
    AppUpdatesFeature.RootReducer()
    AdminFeature.RootReducer()
    AdminWindowFeature.RootReducer()
    FilterFeature.RootReducer()

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
    Scope(state: \.blockedRequests, action: /Action.blockedRequests) {
      BlockedRequestsFeature.Reducer()
    }
    Scope(state: \.admin, action: /Action.admin) {
      AdminFeature.Reducer()
    }
    Scope(state: \.appUpdates, action: /Action.appUpdates) {
      AppUpdatesFeature.Reducer()
    }
    .ifLet(\.user, action: /Action.user) {
      UserFeature.Reducer()
    }
  }
}

struct DeviceState: Equatable {
  var colorScheme = "light" // TODO: enum
  var hasInternetConnection = false
}
