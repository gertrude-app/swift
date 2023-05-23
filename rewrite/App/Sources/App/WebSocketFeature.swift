import ComposableArchitecture
import Core
import Foundation
import Models
import Shared

enum WebSocketFeature {
  enum Action: Equatable, Sendable {
    case connectedSuccessfully
    case receivedMessage(WebSocketMessage.FromApiToApp)
  }

  struct RootReducer: RootReducing {
    @Dependency(\.backgroundQueue) var bgQueue
    @Dependency(\.device) var device
    @Dependency(\.websocket) var websocket
  }
}

extension WebSocketFeature.RootReducer {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    case .heartbeat(.everyFiveMinutes):
      guard state.admin.accountStatus != .inactive else { return .none }
      guard let user = state.user else { return .none }
      return .run { [state] send in
        guard try await websocket.state() != .connected else {
          return
        }
        // try to repair any broken/disconnected websocket connection status
        if try await websocket.connect(with: user.token) == .connected {
          try await websocket.sendFilterState(state.filter)
        }
      }

    case .loadedPersistentState(.some(let persistent)):
      guard state.admin.accountStatus != .inactive else { return .none }
      guard let user = persistent.user else { return .none }
      return connect(user)

    case .filter(.receivedState(let filterState)):
      return .run { [state] _ in
        guard try await websocket.state() == .connected else { return }
        try await websocket.sendFilterState(state.filter, extensionState: filterState)
      }

    case .history(.userConnection(.connect(.success(let user)))):
      return connect(user)

    case .application(.willSleep),
         .application(.willTerminate),
         .adminAuthenticated(.adminWindow(.webview(.reconnectUserClicked))):
      return .run { _ in
        guard try await websocket.state() == .connected else { return }
        try await websocket.send(.goingOffline)
        try await websocket.disconnect()
      }

    case .admin(.accountStatusResponse(.success(.inactive))):
      return .run { _ in
        try await websocket.disconnect()
      }

    case .adminAuthenticated(.adminWindow(.webview(.suspendFilterClicked))),
         .websocket(.receivedMessage(.suspendFilter)):
      guard state.admin.accountStatus != .inactive else { return .none }
      return .run { _ in
        try await websocket.send(.currentFilterState(.suspended))
      }

    case .application(.didWake):
      guard state.admin.accountStatus != .inactive else { return .none }
      guard let user = state.user else { return .none }
      return connect(user)

    case .websocket(let websocketAction):
      guard state.admin.accountStatus != .inactive else { return .none }
      switch websocketAction {

      case .connectedSuccessfully:
        return .run { [state] _ in
          try await websocket.sendFilterState(state.filter)
        }

      case .receivedMessage(.currentFilterStateRequested):
        return .run { [state] _ in
          try await websocket.sendFilterState(state.filter)
        }

      case .receivedMessage(.suspendFilterRequestDenied(let comment)):
        return .run { _ in
          await device.notifyFilterSuspensionDenied(with: comment)
        }

      case .receivedMessage(.unlockRequestUpdated(let status, let target, let comment)):
        return .run { _ in
          await device.notifyUnlockRequestUpdated(
            accepted: status == .accepted,
            target: target,
            comment: comment
          )
        }

      case .receivedMessage:
        return .none
      }

    default:
      return .none
    }
  }

  func connect(_ user: User) -> Effect<Action> {
    .run { send in
      if try await websocket.connect(with: user.token) == .connected {
        await send(.websocket(.connectedSuccessfully))
      }
    }
  }
}

extension WebSocketClient {
  @discardableResult
  func connect(with token: User.Token, customUrl: URL? = nil) async throws -> State {
    try await connect(token.rawValue, customUrl)
  }

  func sendFilterState(
    _ state: FilterFeature.State,
    extensionState: FilterExtensionState? = nil
  ) async throws {
    let userFilterState = UserFilterState(
      extensionState: extensionState ?? state.extension,
      currentSuspensionExpiration: state.currentSuspensionExpiration
    )
    try await send(.currentFilterState(userFilterState))
  }
}
