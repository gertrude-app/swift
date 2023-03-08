import ComposableArchitecture
import CoreGraphics
import Shared

public struct MenuBar: Reducer {
  public struct State: Equatable {
    public var visible = false
    public var screen: Screen = .notConnected

    public enum Screen: Equatable {
      case notConnected
      // case connecting // todo
      case connected(Connected)
    }

    public struct Connected: Equatable {
      public enum FilterState: Equatable {
        case off
        case on
        case suspended(expiration: String)
      }

      public var recordingKeystrokes = false
      public var recordingScreen = false
      public var filterState: FilterState = .off

      public init(
        recordingKeystrokes: Bool = false,
        recordingScreen: Bool = false,
        filterState: FilterState = .off
      ) {
        self.recordingKeystrokes = recordingKeystrokes
        self.recordingScreen = recordingScreen
        self.filterState = filterState
      }
    }

    public init(visible: Bool = false, screen: Screen = .notConnected) {
      self.visible = visible
      self.screen = screen
    }
  }

  public enum Action: String, Equatable {
    case fakeConnect
    case menuBarIconClicked
    case resumeFilterClicked
    case suspendFilterClicked
    case refreshRulesClicked
    case administrateClicked
    case viewNetworkTrafficClicked
  }

  public func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .menuBarIconClicked:
      state.visible.toggle()
      return .none
    case .fakeConnect:
      state.screen = .connected(.init(
        recordingKeystrokes: true,
        recordingScreen: true,
        filterState: .on
      ))
      return .none
    default: // temp
      return .none
    }
  }

  public init() {}
}
