import ComposableArchitecture
import Dependencies
import Foundation
import MacAppRoute
import Models

enum HistoryFeature: Feature {
  struct State: Equatable {
    var userConnection = UserConnectionFeature.State.notConnected
  }

  enum Action: Equatable, Sendable {
    case userConnection(UserConnectionFeature.Action)
  }

  struct Reducer: FeatureReducer {
    typealias State = HistoryFeature.State
    typealias Action = HistoryFeature.Action

    var body: some ReducerOf<Self> {
      Scope(state: \.userConnection, action: /Action.userConnection) {
        UserConnectionFeature.Reducer()
      }
    }
  }

  struct RootReducer {
    @Dependency(\.device) var device
    @Dependency(\.api.connectUser) var connectUser
    @Dependency(\.app.installedVersion) var appVersion
    @Dependency(\.storage.savePersistentState) var save
  }
}

extension HistoryFeature.RootReducer: RootReducing {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .menuBar(.connectClicked):
      if case .notConnected = state.history.userConnection {
        state.history.userConnection = .enteringConnectionCode
      }
      return .none

    case .menuBar(.connectSubmit(let code)):
      guard case .enteringConnectionCode = state.history.userConnection else {
        return .none
      }
      state.history.userConnection = .connecting
      return .task {
        await .history(.userConnection(.connect(TaskResult {
          try await connectUser(connectUserInput(code: code))
        })))
      }

    case .menuBar(.retryConnectClicked):
      guard case .connectFailed = state.history.userConnection else {
        return .none
      }
      state.history.userConnection = .enteringConnectionCode
      return .none

    case .menuBar(.welcomeAdminClicked):
      state.history.userConnection = .established(welcomeDismissed: true)
      return .none

    case .history(.userConnection(.connect(.success(let user)))):
      state.user = user
      return .run { [persistedState = state.persistent] _ in
        try await save(persistedState)
      }

    case .loadedPersistentState(let persisted):
      if persisted?.user != nil {
        state.history.userConnection = .established(welcomeDismissed: true)
      }
      return .none

    default:
      return .none
    }
  }

  private func connectUserInput(code: Int) throws -> ConnectUser.Input {
    guard let serialNumber = device.serialNumber() else {
      throw AppError("No serial number")
    }
    return ConnectUser.Input(
      verificationCode: code,
      appVersion: appVersion() ?? "unknown",
      hostname: device.hostname(),
      modelIdentifier: device.modelIdentifier() ?? "unknown",
      username: device.username(),
      fullUsername: device.fullUsername(),
      numericId: Int(exactly: device.numericUserId())!,
      serialNumber: serialNumber
    )
  }
}
