import ComposableArchitecture
import Dependencies
import Foundation
import MacAppRoute
import Models

struct History {
  enum UserConnection {
    enum State: Equatable {
      case notConnected
      case enteringConnectionCode
      case connecting
      case connectFailed(String)
      case established(welcomeDismissed: Bool)
    }

    enum Action: Equatable, Sendable {
      case connect(TaskResult<User>)
    }
  }

  struct State: Equatable {
    var userConnection = UserConnection.State.notConnected
  }

  enum Action: Equatable, Sendable {
    case userConnection(UserConnection.Action)
  }
}

struct HistoryRoot: Reducer {
  typealias State = AppReducer.State
  typealias Action = AppReducer.Action

  @Dependency(\.device) var device
  @Dependency(\.api.connectUser) var connectUser
  @Dependency(\.app.installedVersion) var appVersion

  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    case .menuBar(.connectClicked):
      if case .notConnected = state.history.userConnection {
        state.history.userConnection = .enteringConnectionCode
      }
      return .none

    case .menuBar(.connectSubmit(let code)):
      guard case .enteringConnectionCode = state.history.userConnection else { return .none }
      state.history.userConnection = .connecting
      return .task {
        await .history(.userConnection(.connect(TaskResult {
          try await connectUser(connectUserInput(code: code))
        })))
      }

    case .menuBar(.retryConnectClicked):
      guard case .connectFailed = state.history.userConnection else { return .none }
      state.history.userConnection = .enteringConnectionCode
      return .none

    case .menuBar(.welcomeAdminClicked):
      state.history.userConnection = .established(welcomeDismissed: true)
      return .none

    case .history(.userConnection(.connect(.success(let user)))):
      state.user = user
      state.history.userConnection = .established(welcomeDismissed: false)
      return .none

    case .history(.userConnection(.connect(.failure(let error)))):
      state.history.userConnection = .connectFailed(error.localizedDescription)
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
