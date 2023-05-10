import ComposableArchitecture
import Core
import Foundation

struct FilterFeature: Feature {
  struct State: Equatable {
    var currentSuspensionExpiration: Date?
    var `extension`: FilterExtensionState = .unknown
  }

  enum Action: Equatable, Sendable {
    case receivedState(FilterExtensionState)
  }

  struct Reducer: FeatureReducer {
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      switch action {
      case .receivedState(let extensionState):
        state.extension = extensionState
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

    case .adminWindow(.delegate(.healthCheckFilterExtensionState(let filterState))):
      state.filter.extension = filterState
      return .none

    // TODO: test
    case .menuBar(.turnOnFilterClicked),
         .adminWindow(.webview(.startFilterClicked)):
      if !state.filter.extension.installed {
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
