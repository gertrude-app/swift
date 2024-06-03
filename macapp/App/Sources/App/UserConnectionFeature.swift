import ComposableArchitecture
import Gertie
import PairQL

enum UserConnectionFeature: Feature {
  enum State: Equatable {
    case notConnected
    case enteringConnectionCode
    case connecting
    case connectFailed(String)
    case established(welcomeDismissed: Bool)
  }

  enum Action: Equatable, Sendable {
    case connect(TaskResult<UserData>)
    case disconnectMissingUser
  }

  struct Reducer: FeatureReducer {
    @Dependency(\.api) var api
  }

  struct RootReducer: RootReducing {
    @Dependency(\.api) var api
    @Dependency(\.app) var app
    @Dependency(\.storage) var storage
    @Dependency(\.filterXpc) var xpc
  }
}

extension UserConnectionFeature.Reducer {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .connect(.success):
      state = .established(welcomeDismissed: false)
      return .none

    case .connect(.failure(let error)):
      let codeNotFound = "Code not found, or expired. Try reentering, or create a new code."
      state = .connectFailed(error.userMessage([.connectionCodeNotFound: codeNotFound]))
      return .none

    case .disconnectMissingUser:
      return .none // handled by root reducer
    }
  }
}

extension UserConnectionFeature.RootReducer {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .adminAuthed(.adminWindow(.webview(.disconnectUserClicked))):
      state.user = .init()
      state.history.userConnection = .notConnected
      state.adminWindow.windowOpen = false
      state.menuBar.dropdownOpen = true
      return self.disconnectUser(persisting: state.persistent)

    case .websocket(.receivedMessage(.userDeleted)),
         .history(.userConnection(.disconnectMissingUser)):
      state.user = .init()
      state.history.userConnection = .notConnected
      return .merge(
        self.disconnectUser(persisting: state.persistent),
        .exec { send in
          await send(.focusedNotification(.text(
            "Child deleted",
            "The child associated with this computer was deleted. You'll need to connect to a different child, or quit the app."
          )))
        }
      )

    default:
      return .none
    }
  }

  func disconnectUser(persisting updated: Persistent.State) -> Effect<Action> {
    .merge(
      .exec { _ in
        await api.clearUserToken()
        try await storage.savePersistentState(updated)
        _ = await xpc.disconnectUser()
        await app.disableLaunchAtLogin()
        await app.stopRelaunchWatcher()
      },
      .cancel(id: AppReducer.CancelId.heartbeatInterval),
      .cancel(id: AppReducer.CancelId.websocketMessages)
    )
  }
}

extension UserConnectionFeature.Reducer {
  typealias State = UserConnectionFeature.State
  typealias Action = UserConnectionFeature.Action
}
