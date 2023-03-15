import ComposableArchitecture

// public, not nested, because it's used in the AppDelegate
public enum AppDelegateAction: Equatable, Sendable {
  case didFinishLaunching
}

struct AppDelegateReducer: Reducer {
  struct State: Equatable {}
  typealias Action = AppDelegateAction

  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .didFinishLaunching:
      return .none
    }
  }
}
