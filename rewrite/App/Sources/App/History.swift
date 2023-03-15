import ComposableArchitecture
import Dependencies
import Models

struct History: Reducer {
  struct UserConnection: Reducer {
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

    @Dependency(\.apiClient.connectUser) var connectUser

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      switch (state, action) {
      case (.notConnected, .connectClicked):
        state = .enteringConnectionCode
        return .none
      case (.enteringConnectionCode, .connectSubmitted(let code)):
        state = .connecting
        return .task {
          await .connectResponse(TaskResult {
            try await connectUser(code)
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
