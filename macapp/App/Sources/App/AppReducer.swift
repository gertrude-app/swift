import ClientInterfaces
import Combine
import ComposableArchitecture
import Core
import Foundation
import Gertie
import MacAppRoute
import os.log

struct AppReducer: Reducer, Sendable {
  struct State: Equatable, Sendable {
    var admin = AdminFeature.State()
    var adminWindow = AdminWindowFeature.State()
    var appUpdates = AppUpdatesFeature.State()
    var blockedRequests = BlockedRequestsFeature.State()
    var filter = FilterFeature.State()
    var history = HistoryFeature.State()
    var menuBar = MenuBarFeature.State()
    var requestSuspension = RequestSuspensionFeature.State()
    var user: UserFeature.State?
  }

  enum Action: Equatable, Sendable {
    enum FocusedNotification: Equatable, Sendable {
      case unexpectedError
      case text(String, String)
    }

    case admin(AdminFeature.Action)
    case adminWindow(AdminWindowFeature.Action)
    case application(ApplicationFeature.Action)
    case appUpdates(AppUpdatesFeature.Action)
    case filter(FilterFeature.Action)
    case focusedNotification(FocusedNotification)
    case xpc(XPCEvent.App)
    case history(HistoryFeature.Action)
    case menuBar(MenuBarFeature.Action)
    case monitoring(MonitoringFeature.Action)
    case loadedPersistentState(Persistent.State?)
    case user(UserFeature.Action)
    case heartbeat(Heartbeat.Interval)
    case blockedRequests(BlockedRequestsFeature.Action)
    case requestSuspension(RequestSuspensionFeature.Action)
    case websocket(WebSocketFeature.Action)

    indirect case adminAuthenticated(Action)
  }

  @Dependency(\.api) var api
  @Dependency(\.device) var device
  @Dependency(\.backgroundQueue) var bgQueue

  var body: some ReducerOf<Self> {
    Reduce<State, Action> { state, action in
      #if !DEBUG
        os_log("[G•] APP received action: %{public}@", String(describing: action))
      #endif
      switch action {
      case .loadedPersistentState(.some(let persistent)):
        guard let user = persistent.user else { return .none }
        state.user = .init(data: user)
        return .exec { send in
          await api.setUserToken(user.token)
          try await bgQueue.sleep(for: .milliseconds(10)) // <- unit test determinism
          return await send(.user(.refreshRules(
            result: TaskResult { try await api.refreshUserRules() },
            userInitiated: false
          )))
        }

      case .focusedNotification(let notification):
        // dismiss windows/dropdowns so notification is visible, i.e. "focused"
        state.adminWindow.windowOpen = false
        state.menuBar.dropdownOpen = false
        state.blockedRequests.windowOpen = false
        state.requestSuspension.windowOpen = false
        return .exec { _ in
          switch notification {
          case .unexpectedError:
            await device.notifyUnexpectedError()
          case .text(let title, let body):
            await device.showNotification(title, body)
          }
        }

      default:
        return .none
      }
    }

    // root reducers
    ApplicationFeature.RootReducer()
    HistoryFeature.RootReducer()
    UserFeature.RootReducer()
    BlockedRequestsFeature.RootReducer()
    AppUpdatesFeature.RootReducer()
    AdminFeature.RootReducer()
    AdminWindowFeature.RootReducer()
    FilterFeature.RootReducer()
    MonitoringFeature.RootReducer()
    RequestSuspensionFeature.RootReducer()
    WebSocketFeature.RootReducer()
    UserConnectionFeature.RootReducer()
    MenuBarFeature.RootReducer()

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
    Scope(state: \.requestSuspension, action: /Action.requestSuspension) {
      RequestSuspensionFeature.Reducer()
    }
    .ifLet(\.user, action: /Action.user) {
      UserFeature.Reducer()
    }
  }
}
