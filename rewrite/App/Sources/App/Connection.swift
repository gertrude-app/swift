import ComposableArchitecture
import Foundation

public struct Connection: Reducer {
  public enum State: Equatable {
    case notConnected
    case enteringConnectionCode
    case connecting
    case connectFailed(String)
    case connected(User)
  }

  public enum Action: Equatable, Decodable, Sendable {
    case connectClicked
    case tryConnect(code: Int)
    case connectFailed(String)
    case connectSucceeded(User)
  }

  public func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch (state, action) {
    case (.notConnected, .connectClicked):
      print(" i should ge there..")
      state = .enteringConnectionCode
      return .none
    case (.enteringConnectionCode, .tryConnect(let code)):
      print("sending connect api request with code \(code) 🚀")
      state = .connecting
      return .none
    case (.connecting, .connectFailed(let error)):
      state = .connectFailed(error)
      return .none
    case (.connecting, .connectSucceeded(let user)):
      state = .connected(user)
      return .none
    default:
      print("not here hopefully")
      return .none
    }
  }
}

public struct User: Equatable, Codable, Sendable {
  // public var token: UUID // TODO: tagged
  public var name: String
  public var keyloggingEnabled: Bool
  public var screenshotsEnabled: Bool
  public var screenshotFrequency: Int
  public var screenshotSize: Int
}
