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
    @Dependency(\.storage) var storage
    @Dependency(\.filterXpc) var xpc
  }
}

extension UserConnectionFeature.Reducer {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .connect(.success(let user)):
      state = .established(welcomeDismissed: false)
      return .run { _ in
        await api.setUserToken(user.token)
      }

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
    case .adminAuthenticated(.adminWindow(.webview(.reconnectUserClicked))):
      state.user = nil
      state.history.userConnection = .notConnected
      state.adminWindow.windowOpen = false
      state.menuBar.dropdownOpen = true
      return disconnectUser(persisting: state.persistent)

    case .websocket(.receivedMessage(.userDeleted)),
         .history(.userConnection(.disconnectMissingUser)):
      state.user = nil
      state.history.userConnection = .notConnected
      return .merge(
        disconnectUser(persisting: state.persistent),
        .run { send in
          await send(.focusedNotification(.text(
            "User deleted",
            "The user associated with this device was deleted. You'll need to connect to a different user, or quit the app."
          )))
        }
      )

    default:
      return .none
    }
  }

  func disconnectUser(persisting updatedState: Persistent.State) -> Effect<Action> {
    .run { send in
      await api.clearUserToken()
      try await storage.savePersistentState(updatedState)
      _ = await xpc.disconnectUser()
    }
  }
}

extension UserConnectionFeature.Reducer {
  typealias State = UserConnectionFeature.State
  typealias Action = UserConnectionFeature.Action
}
