import ComposableArchitecture
import Dependencies
import Foundation
import Models

struct History: Reducer {
  struct UserConnection: Reducer {
    @Dependency(\.api.connectUser) var connectUser
    @Dependency(\.device) var device
    @Dependency(\.app.installedVersion) var appVersion

    enum State: Equatable {
      case notConnected
      case enteringConnectionCode
      case connecting
      case connectFailed(String)
      case established(welcomeDismissed: Bool)
    }

    enum Action: Equatable, Sendable {
      case connectClicked
      case retryConnectClicked
      case connectSubmitted(code: Int)
      case connectResponse(TaskResult<User>)
      case welcomeDismissed
    }

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      switch (state, action) {
      case (.notConnected, .connectClicked):
        state = .enteringConnectionCode
        return .none
      case (.enteringConnectionCode, .connectSubmitted(let code)):
        state = .connecting
        return .task {
          await .connectResponse(TaskResult {
            guard let serialNumber = device.serialNumber() else {
              throw AppError("No serial number")
            }
            return try await connectUser(.init(
              verificationCode: code,
              appVersion: appVersion() ?? "unknown",
              hostname: device.hostname(),
              modelIdentifier: device.modelIdentifier() ?? "unknown",
              username: device.username(),
              fullUsername: device.fullUsername(),
              numericId: Int(exactly: device.numericUserId())!,
              serialNumber: serialNumber
            ))
          })
        }
      case (.connecting, .connectResponse(.success)):
        state = .established(welcomeDismissed: false)
        return .none
      case (.connecting, .connectResponse(.failure(let error))):
        state = .connectFailed(error.localizedDescription)
        return .none
      case (.established, .welcomeDismissed):
        state = .established(welcomeDismissed: true)
        return .none
      case (.connectFailed, .retryConnectClicked):
        state = .enteringConnectionCode
        return .none
      default:
        return .none
      }
    }
  }

  struct State: Equatable {
    var userConnection = UserConnection.State.notConnected
  }

  enum Action: Equatable, Sendable {
    case userConnection(UserConnection.Action)
  }

  var body: some ReducerOf<Self> {
    Scope(state: \.userConnection, action: /Action.userConnection) {
      UserConnection()
    }
  }
}
