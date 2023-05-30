import ComposableArchitecture
import Foundation

enum MenuBarFeature: Feature {
  struct State: Equatable {
    var dropdownOpen = false
  }

  enum Action: Equatable, Decodable, Sendable {
    case menuBarIconClicked
    case resumeFilterClicked
    case suspendFilterClicked
    case refreshRulesClicked
    case administrateClicked
    case viewNetworkTrafficClicked
    case connectClicked
    case connectSubmit(code: Int)
    case retryConnectClicked
    case connectFailedHelpClicked
    case welcomeAdminClicked
    case turnOnFilterClicked
  }

  struct Reducer: FeatureReducer {
    @Dependency(\.device) var device
  }
}

extension MenuBarFeature.Reducer {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .menuBarIconClicked:
      state.dropdownOpen.toggle()
      return .none

    // get menu bar out of the way after certain actions
    case .refreshRulesClicked,
         .administrateClicked,
         .viewNetworkTrafficClicked,
         .suspendFilterClicked:
      state.dropdownOpen = false
      return .none

    case .connectFailedHelpClicked:
      return .run { _ in
        await device.openWebUrl(URL(string: "https://gertrude.app/contact")!)
      }

    default:
      return .none
    }
  }
}

extension MenuBarFeature.Reducer {
  typealias State = MenuBarFeature.State
  typealias Action = MenuBarFeature.Action
}
