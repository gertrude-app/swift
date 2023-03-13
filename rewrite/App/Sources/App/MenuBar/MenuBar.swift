import ComposableArchitecture

public struct MenuBar {
  public enum State: Equatable, Encodable {
    public struct Connected: Equatable {
      public enum FilterState: Equatable, Codable {
        case off
        case on
        case suspended(expiration: String)
      }

      public var filterState: FilterState
      public var recordingScreen: Bool
      public var recordingKeystrokes: Bool
    }

    case notConnected
    case enteringConnectionCode
    case connecting
    case connectionFailed(error: String)
    case connectionSucceded(userName: String)
    case connected(Connected)
  }

  public enum Action: Equatable, Decodable, Sendable {
    case menuBarIconClicked // todo, wierd...
    case resumeFilterClicked
    case suspendFilterClicked
    case refreshRulesClicked
    case administrateClicked
    case viewNetworkTrafficClicked
    case connectClicked
    case connectSubmit(code: Int)
    case retryConnectClicked
    case welcomeAdminClicked
  }

  public init() {}
}
