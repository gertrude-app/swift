import ComposableArchitecture
import Foundation

enum MenuBarFeature: Feature {
  enum State: Equatable, Encodable {
    struct Connected: Equatable {
      var filterState: FilterState
      var recordingScreen: Bool
      var recordingKeystrokes: Bool
    }

    case notConnected
    case enteringConnectionCode
    case connecting
    case connectionFailed(error: String)
    case connectionSucceded(userName: String)
    case connected(Connected)
  }

  enum Action: Equatable, Decodable, Sendable {
    case menuBarIconClicked // todo, wierd...
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
    @Dependency(\.filterXpc) var xpc
    @Dependency(\.filterExtension) var filterExtension
    @Dependency(\.updater) var updater // temp
  }

  struct RootReducer: RootReducing {
    @Dependency(\.api) var api
  }
}

extension MenuBarFeature.Reducer {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    case .connectFailedHelpClicked:
      return .run { _ in
        await device.openWebUrl(URL(string: "https://gertrude.app/contact")!)
      }

    // TODO: temporary
    case .administrateClicked:
      return .run { _ in
        print("establish connection:", await xpc.establishConnection())
      }

    default:
      return .none
    }
  }
}

extension MenuBarFeature.RootReducer {
  func reduce(into state: inout State, action: Action) -> Effect<Self.Action> {
    switch action {

    case .menuBar(.refreshRulesClicked):
      // TODO: close menu bar so they can see the notification
      return .task {
        await .user(.refreshRules(
          result: TaskResult { try await api.refreshUserRules() },
          userInitiated: true
        ))
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
