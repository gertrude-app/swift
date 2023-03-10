import ComposableArchitecture
import Foundation

public enum FilterState: Equatable {
  case unknown
  case notInstalled
  case off
  case on
  case suspended(resuming: Date)
}

public struct AppState: Equatable {
  public var version = "(unknown)"
  public var updateChannel = "release" // TODO: enum
  public var menuBarDropdownVisible = false
}

public struct DeviceState: Equatable {
  public var colorScheme = "light" // TODO: enum
  public var hasInternetConnection = false
}

public struct AdminState: Equatable {
  public var accountStatus = "active" // TODO: enum
}

public struct AppReducer: Reducer {
  public struct State: Equatable {
    public var admin = AdminState()
    public var app = AppState()
    public var device = DeviceState()
    public var filter = FilterState.unknown
    public var connection = Connection.State.notConnected
    public init() {}
  }

  public enum Action: Equatable, Sendable {
    case delegate(AppDelegateReducer.Action)
    case connection(Connection.Action)
    case menuBar(MenuBar.Action)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .menuBar(.connectClicked):
        return .send(.connection(.connectClicked))
      case .menuBar(.connectSubmit(let code)):
        return .send(.connection(.tryConnect(code: code)))
      default:
        return .none
      }
    }
    Scope(state: \.connection, action: /Action.connection) {
      Connection()
    }
  }

  public init() {}
}
