import ComposableArchitecture
import Models

struct FilterReducer: Reducer, Sendable {
  typealias State = FilterState

  enum Action: Equatable {
    case receivedState(FilterState)
  }

  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .receivedState(let newState):
      state = newState
      return .none
    }
  }
}
