import ClientInterfaces
import ComposableArchitecture
import Core
import Foundation
import Gertie

enum WebSocketFeature {
  enum Action: Equatable, Sendable {
    case connectedSuccessfully
    case receivedMessage(WebSocketMessage.FromApiToApp)
  }

  struct RootReducer: RootReducing {
    typealias Action = AppReducer.Action
    typealias State = AppReducer.State
    @Dependency(\.backgroundQueue) var bgQueue
    @Dependency(\.device) var device
    @Dependency(\.websocket) var websocket
    @Dependency(\.network) var network
    @Dependency(\.date.now) var now
  }
}

extension WebSocketFeature.RootReducer {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    case .heartbeat(.everyMinute),
         .requestSuspension(.webview(.requestSubmitted)),
         .blockedRequests(.webview(.unlockRequestSubmitted)):
      guard state.admin.accountStatus != .inactive,
            let user = state.user.data,
            network.isConnected() else {
        return .none
      }
      return .exec { [state] send in
        guard try await websocket.state() != .connected else {
          return
        }
        // try to repair any broken/disconnected websocket connection status
        if try await websocket.connect(user.token) == .connected {
          try await websocket.sendFilterState(state)
        }
      }

    case .startProtecting(user: let user):
      guard state.admin.accountStatus != .inactive else { return .none }
      return self.connect(user)

    case .filter(.receivedState(let filterState)):
      return .exec { [state] _ in
        guard try await websocket.state() == .connected else { return }
        try await websocket.sendFilterState(state, overrideFilterState: filterState)
      }

    case .history(.userConnection(.connect(.success(let user)))):
      return self.connect(user)

    case .application(.willSleep),
         .application(.willTerminate),
         .websocket(.receivedMessage(.userDeleted)),
         .history(.userConnection(.disconnectMissingUser)),
         .adminAuthed(.adminWindow(.webview(.confirmQuitAppClicked))),
         .adminAuthed(.adminWindow(.webview(.disconnectUserClicked))):
      return .exec { _ in
        guard try await websocket.state() == .connected else { return }
        try await websocket.send(.goingOffline)
        try await websocket.disconnect()
      }

    case .checkIn(result: .success(let res), _) where res.adminAccountStatus == .inactive:
      return .exec { _ in
        try await websocket.disconnect()
      }

    case .adminAuthed(.requestSuspension(.webview(.grantSuspensionClicked(let durationInSeconds)))):
      guard state.admin.accountStatus != .inactive else { return .none }
      return .exec { _ in
        let expiration = self.now + .seconds(durationInSeconds)
        try await websocket.send(.currentFilterState_v2(.suspended(resuming: expiration)))
      }

    case .application(.didWake):
      guard state.admin.accountStatus != .inactive else { return .none }
      guard let user = state.user.data else { return .none }
      return self.connect(user)

    case .websocket(let websocketAction):
      guard state.admin.accountStatus != .inactive else { return .none }
      switch websocketAction {

      case .connectedSuccessfully:
        return .exec { [state] _ in
          try await websocket.sendFilterState(state)
        }

      case .receivedMessage(.currentFilterStateRequested):
        return .exec { [state] _ in
          try await websocket.sendFilterState(state)
        }

      case .receivedMessage(.unlockRequestUpdated_v2(_, let status, let target, let comment)):
        return .exec { _ in
          await device.notifyUnlockRequestUpdated(
            accepted: status == .accepted,
            target: target,
            comment: comment
          )
        }

      case .receivedMessage(.userDeleted):
        return .none // handled above, with other disconnect-like actions

      case .receivedMessage(.userUpdated):
        return .none // handled by user feature, which triggers a checkin

      case .receivedMessage(.filterSuspensionRequestDecided_v2):
        return .none // handled by filter feature AND monitoring feature
      }

    case .adminAuthed(.adminWindow(.webview(.advanced(.websocketEndpointSet(let url))))):
      let user = state.user.data
      return .exec { send in
        await websocket.updateEndpointOverride(url)
        try await websocket.send(.goingOffline)
        try await websocket.disconnect()
        if let user, try await websocket.connect(user.token) == .connected {
          await send(.websocket(.connectedSuccessfully))
        }
      }

    default:
      return .none
    }
  }

  func connect(_ user: UserData) -> Effect<Action> {
    .exec { send in
      if try await websocket.connect(user.token) == .connected {
        await send(.websocket(.connectedSuccessfully))
      }
    }
  }
}

extension WebSocketClient {
  func sendFilterState(
    _ state: AppReducer.State,
    overrideFilterState: FilterExtensionState? = nil
  ) async throws {
    if let overrideFilterState {
      var stateCopy = state
      stateCopy.filter.extension = overrideFilterState
      try await send(.currentFilterState_v2(.init(from: stateCopy)))
    } else {
      try await send(.currentFilterState_v2(.init(from: state)))
    }
  }
}
