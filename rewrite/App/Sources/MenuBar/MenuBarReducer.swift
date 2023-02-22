import ComposableArchitecture
import CoreGraphics
import Shared

public struct MenuBar: Reducer {
  public struct State: Equatable {
    public var visible = false
    public var user: User?

    public struct User: Equatable {
      public var filterRunning = false
      public var recordingKeystrokes = false
      public var recordingScreen = false
      public var filterState: FilterState = .off
      public var filterSuspension: FilterSuspension?

      public init(
        filterRunning: Bool = false,
        recordingKeystrokes: Bool = false,
        recordingScreen: Bool = false,
        filterState: FilterState = .off,
        filterSuspension: FilterSuspension? = nil
      ) {
        self.filterRunning = filterRunning
        self.recordingKeystrokes = recordingKeystrokes
        self.recordingScreen = recordingScreen
        self.filterState = filterState
        self.filterSuspension = filterSuspension
      }
    }

    public init(visible: Bool = false, user: MenuBar.State.User? = nil) {
      self.visible = visible
      self.user = user
    }
  }

  public enum Action: String, Equatable {
    case menuBarIconClicked
    case fakeConnect
  }

  public func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .menuBarIconClicked:
      state.visible.toggle()
      return .none
    case .fakeConnect:
      state.user = .init(
        filterRunning: true,
        recordingKeystrokes: true,
        recordingScreen: true,
        filterState: .on
      )
      return .none
    }
  }

  public init() {}
}
