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
    case removeFilterClicked
    case connectFailedHelpClicked
    case welcomeAdminClicked
    case turnOnFilterClicked
    case updateNagDismissClicked
    case updateNagUpdateClicked
    case updateRequiredUpdateClicked
    case quitForNowClicked
    case quitForUninstallClicked
  }

  struct Reducer: FeatureReducer {
    @Dependency(\.device) var device
  }

  struct RootReducer: AdminAuthenticating {
    @Dependency(\.app) var app
    @Dependency(\.filterXpc) var xpc
    @Dependency(\.filterExtension) var filter
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.storage) var storage
    @Dependency(\.security) var security
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
      return .exec { _ in
        await device.openWebUrl(URL(string: "https://gertrude.app/contact")!)
      }

    default:
      return .none
    }
  }
}

extension MenuBarFeature.RootReducer {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    case .menuBar(.quitForNowClicked):
      return adminAuthenticated(action)

    case .adminAuthenticated(.menuBar(.quitForNowClicked)):
      return .exec { _ in await app.quit() }

    case .menuBar(.removeFilterClicked):
      return adminAuthenticated(action)

    case .adminAuthenticated(.menuBar(.removeFilterClicked)):
      return .exec { _ in _ = await filter.uninstall() }

    case .menuBar(.quitForUninstallClicked):
      return adminAuthenticated(action)

    case .adminAuthenticated(.menuBar(.quitForUninstallClicked)):
      return .exec { _ in
        _ = await xpc.disconnectUser()
        _ = await filter.uninstall()
        await storage.deleteAllPersistentState()
        try? await mainQueue.sleep(for: .milliseconds(100))
        await app.quit()
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
