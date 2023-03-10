import ComposableArchitecture

public struct MenuBar {
  public struct State: Equatable, Encodable {
    public enum FilterState: Equatable {
      case off
      case on
      case suspended(expiration: String)
    }

    public var connection = Connection.State.notConnected
    public var filterState = FilterState.off

    public init(
      connection: Connection.State = .notConnected,
      filterState: FilterState = .off
    ) {
      self.connection = connection
      self.filterState = filterState
    }
  }

  public enum Action: Equatable, Sendable {
    case menuBarIconClicked
    case resumeFilterClicked
    case suspendFilterClicked
    case refreshRulesClicked
    case administrateClicked
    case viewNetworkTrafficClicked
    case connectClicked
    case connectSubmit(code: Int)
  }

  public init() {}
}
