import ComposableArchitecture
import Dependencies

public struct History: Reducer {
  public struct UserConnection: Reducer {
    public enum State: Equatable {
      case notConnected
      case enteringConnectionCode
      case connecting
      case connectFailed(String)
      case established(welcomeDismissed: Bool)
    }

    public enum Action: Equatable, Sendable {
      case connectClicked
      case retryConnectClicked
      case connectSubmitted(code: Int)
      case connectResponse(TaskResult<User>)
      case welcomeDismissed
    }

    @Dependency(\.apiClient) var apiClient

    public func reduce(into state: inout State, action: Action) -> Effect<Action> {
      switch (state, action) {
      case (.notConnected, .connectClicked):
        state = .enteringConnectionCode
        return .none
      case (.enteringConnectionCode, .connectSubmitted(let code)):
        state = .connecting
        return .task { [connectUser = apiClient.connectUser] in
          await .connectResponse(TaskResult { try await connectUser(code) })
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

  public struct State: Equatable {
    public var userConnection = UserConnection.State.notConnected
  }

  public enum Action: Equatable, Sendable {
    case userConnection(UserConnection.Action)
  }

  public var body: some ReducerOf<Self> {
    Scope(state: \.userConnection, action: /Action.userConnection) {
      UserConnection()
    }
  }
}
