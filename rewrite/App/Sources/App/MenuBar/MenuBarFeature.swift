import ComposableArchitecture
import Foundation

enum MenuBarFeature: Feature {
  enum State: Equatable, Encodable {
    struct Connected: Equatable {
      enum FilterState: Equatable, Codable {
        case off
        case on
        case suspended(expiration: String)
      }

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
    @Dependency(\.filterXpc) var filterXpc
    @Dependency(\.filterExtension) var filterExtension
  }

  struct RootReducer: RootReducing {
    @Dependency(\.api) var api
    @Dependency(\.filterExtension) var filterExtension
    @Dependency(\.filterXpc) var filterXpc // temp
  }
}

extension MenuBarFeature.Reducer {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    case .connectFailedHelpClicked:
      return .fireAndForget {
        await device.openWebUrl(URL(string: "https://gertrude.app/contact")!)
      }

    // TODO: temporary
    case .suspendFilterClicked:
      return .fireAndForget { _ = await filterExtension.stop() }

    // TODO: temporary
    case .administrateClicked:
      return .fireAndForget {
        print("establish connection:", await filterXpc.establishConnection())
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
      return .task {
        await .user(.refreshRules(
          result: TaskResult { try await api.refreshUserRules() },
          userInitiated: true
        ))
      }

    // temp, just testing...
    case .menuBar(.viewNetworkTrafficClicked):
      return .fireAndForget {
        _ = await filterXpc.setBlockStreaming(true)
      }

    // TODO: test
    case .menuBar(.turnOnFilterClicked):
      if state.filter == .notInstalled {
        // TODO: handle install timout, error, etc
        return .fireAndForget { _ = await filterExtension.install() }
      } else {
        return .fireAndForget { _ = await filterExtension.start() }
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