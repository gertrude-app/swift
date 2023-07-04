import ClientInterfaces
import ComposableArchitecture
import Dependencies
import Foundation
import MacAppRoute

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
    @Dependency(\.api) var api
    @Dependency(\.app) var app
    @Dependency(\.device) var device
    @Dependency(\.network) var network
    @Dependency(\.storage) var storage
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
      if !network.isConnected() {
        return .run { _ in await device.notifyNoInternet() }
      }
      state.history.userConnection = .connecting
      return .task {
        await .history(.userConnection(.connect(TaskResult {
          try await api.connectUser(connectUserInput(code: code))
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

    // consider closing the menu bar the same as dismissing welcome with direct click
    case .menuBar(.menuBarIconClicked)
      where state.history.userConnection == .established(welcomeDismissed: false):
      state.history.userConnection = .established(welcomeDismissed: true)
      return .none

    case .history(.userConnection(.connect(.success(let user)))):
      state.user = user
      return .run { [persistent = state.persistent] _ in
        try await storage.savePersistentState(persistent)
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
      struct NoSerialNumber: Error {}
      throw NoSerialNumber()
    }
    return ConnectUser.Input(
      verificationCode: code,
      appVersion: app.installedVersion() ?? "unknown",
      hostname: device.hostname(),
      modelIdentifier: device.modelIdentifier() ?? "unknown",
      username: device.username(),
      fullUsername: device.fullUsername(),
      numericId: Int(exactly: device.numericUserId())!,
      serialNumber: serialNumber
    )
  }
}
