import ComposableArchitecture

// public, not nested, because it's used in the AppDelegate
public enum ApplicationAction: Equatable, Sendable {
  case didFinishLaunching
  case willTerminate
}

struct Application: Reducer, Sendable {
  struct State: Equatable {}
  typealias Action = ApplicationAction

  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .didFinishLaunching, .willTerminate:
      return .none
    }
  }
}
