import ComposableArchitecture

public struct History: Reducer {
  public struct UserConnection: Reducer {
    public enum State: Equatable {
      case notConnected
      case enteringConnectionCode
      case connecting
      case connectFailed(String)
      case established(welcomeDismissed: Bool)
    }

    public enum Action: Equatable, Decodable, Sendable {
      case connectClicked
      case connectSubmitted(code: Int)
      case connectFailed(String)
      case connectSucceeded
      case welcomeDismissed
    }

    public func reduce(into state: inout State, action: Action) -> Effect<Action> {
      switch (state, action) {
      case (.notConnected, .connectClicked):
        state = .enteringConnectionCode
        return .none
      case (.enteringConnectionCode, .connectSubmitted):
        state = .connecting
        return .none
      case (.connecting, .connectFailed(let error)):
        state = .connectFailed(error)
        return .none
      case (.connecting, .connectSucceeded):
        state = .established(welcomeDismissed: false)
        return .none
      case (.established, .welcomeDismissed):
        state = .established(welcomeDismissed: true)
        return .none
      default:
        return .none
      }
    }
  }

  public struct State: Equatable {
    public var userConnection = UserConnection.State.notConnected
  }

  public enum Action: Equatable, Decodable, Sendable {
    case userConnection(UserConnection.Action)
  }

  public var body: some ReducerOf<Self> {
    Scope(state: \.userConnection, action: /Action.userConnection) {
      UserConnection()
    }
  }
}
