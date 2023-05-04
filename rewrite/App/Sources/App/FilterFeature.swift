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

  struct RootReducer: RootReducing {
    @Dependency(\.filterExtension) var filterExtension
  }
}

extension FilterFeature.RootReducer {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    // TODO: test
    case .menuBar(.turnOnFilterClicked):
      if state.filter == .notInstalled {
        // TODO: handle install timout, error, etc
        return .run { _ in _ = await filterExtension.install() }
      } else {
        return .run { _ in _ = await filterExtension.start() }
      }
    default:
      return .none
    }
  }
}
