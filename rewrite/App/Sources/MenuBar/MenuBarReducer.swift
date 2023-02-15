import ComposableArchitecture

// TODO: shared
public enum FilterState: String, Codable, CaseIterable, Equatable {
  case on
  case off
  case suspended
}

public struct MenuBar: Reducer {
  public struct State: Equatable {
    public var visible = false
    public var user: User?

    public struct User: Equatable {
      public var filterRunning = false
      public var recordingKeystrokes = false
      public var recordingScreen = false
      public var filterState: FilterState = .off
    }

    public init() {}
  }

  public enum Action: Equatable {
    case menuBarIconClicked
    case fakeConnect
  }

  public func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .menuBarIconClicked:
      state.visible.toggle()
      return .none
    case .fakeConnect:
      state.user = .init()
      return .none
    }
  }

  public init() {}
}
