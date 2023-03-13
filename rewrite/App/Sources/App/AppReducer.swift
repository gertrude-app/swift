import ComposableArchitecture
import Foundation

// TODO: moveme
public struct User: Equatable, Codable, Sendable {
  // public var token: UUID
  public var name: String
  public var keyloggingEnabled: Bool
  public var screenshotsEnabled: Bool
  public var screenshotFrequency: Int
  public var screenshotSize: Int
  // public var connectedAt: Date
}

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
    public var history = History.State()
    public var user: User?
    public init() {}
  }

  public enum Action: Equatable, Sendable {
    case delegate(AppDelegateReducer.Action)
    case history(History.Action)
    case menuBar(MenuBar.Action)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .menuBar(.connectClicked):
        return .send(.history(.userConnection(.connectClicked)))
      case .menuBar(.connectSubmit(let code)):
        return .send(.history(.userConnection(.connectSubmitted(code: code))))
      default:
        return .none
      }
    }
    Scope(state: \.history, action: /Action.history) {
      History()
    }
  }

  public init() {}
}
