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
    var filter = FilterReducer.State.unknown
    var history = HistoryReducer.State()
    var user: UserReducer.State?
  }

  enum Action: Equatable, Sendable {
    case application(Application.Action)
    case filter(FilterReducer.Action)
    case receivedXpcEvent(XPCEvent)
    case history(HistoryReducer.Action)
    case menuBar(MenuBar.Action)
    case loadedPersistentState(Persistent.State?)
    case user(UserReducer.Action)
    case heartbeat
  }

  @Dependency(\.api) var api
  @Dependency(\.app) var appClient
  @Dependency(\.backgroundQueue) var bgQueue
  @Dependency(\.mainQueue) var mainQueue
  @Dependency(\.storage) var storage
  @Dependency(\.filterXpc) var filterXpc
  @Dependency(\.filterExtension) var filterExtension

  private enum HeartbeatCancelId {}

  var body: some ReducerOf<Self> {
    Reduce<State, Action> { state, action in
      switch action {

      case .application(.willTerminate):
        return .cancel(id: HeartbeatCancelId.self)

      case .application(.didFinishLaunching):
        return .merge(
          .run { send in
            await send(.loadedPersistentState(try await storage.loadPersistentState()))
            let setupState = await filterExtension.setup()
            await send(.filter(.receivedState(setupState)))
            if setupState == .on {
              _ = await filterXpc.establishConnection()
            }
          },
          .run { send in
            for await _ in bgQueue.timer(interval: .seconds(60 * 30)) {
              await send(.heartbeat)
            }
          }.cancellable(id: HeartbeatCancelId.self),
          .publisher {
            // TODO: when filter goes _TO_ .notInstalled, the NSXPCConnection
            // becomes useless, we should re-create/invalidate it then
            filterExtension.stateChanges()
              .map { .filter(.receivedState($0)) }
              .receive(on: mainQueue)
          },
          .publisher {
            filterXpc.events()
              .map { .receivedXpcEvent($0) }
              .receive(on: mainQueue)
          }
        )

      case .heartbeat:
        guard state.user != nil else { return .none }
        return .task {
          await .user(.refreshRules(TaskResult {
            let appVersion = appClient.installedVersion() ?? "unknown"
            return try await api.refreshRules(.init(appVersion: appVersion))
          }))
        }

      case .loadedPersistentState(let persistent):
        guard let user = persistent?.user else { return .none }
        state.user = user
        state.history.userConnection = .established(welcomeDismissed: true)
        return .task {
          await api.setUserToken(user.token)
          return await .user(.refreshRules(TaskResult {
            let appVersion = appClient.installedVersion() ?? "unknown"
            return try await api.refreshRules(.init(appVersion: appVersion))
          }))
        }

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
    HistoryRootReducer()
    Scope(state: \.filter, action: /Action.filter) {
      FilterReducer()
    }
    .ifLet(\.user, action: /Action.user) {
      UserReducer()
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
