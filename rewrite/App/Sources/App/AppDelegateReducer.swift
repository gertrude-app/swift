import ComposableArchitecture

public struct AppDelegateReducer: Reducer {
  public struct State: Equatable {}
  public enum Action: Equatable {
    case didFinishLaunching
  }

  public func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .didFinishLaunching:
      return .none
    }
  }
}
