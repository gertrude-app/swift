import ComposableArchitecture
import Models

struct FilterFeature: Feature {
  typealias State = FilterState

  enum Action: Equatable, Sendable {
    case receivedState(FilterState)
  }

  struct Reducer: FeatureReducer {
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      switch action {
      case .receivedState(let newState):
        state = newState
        return .none
      }
    }
  }
}
