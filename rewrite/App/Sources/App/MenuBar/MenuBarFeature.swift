import ComposableArchitecture

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
    case welcomeAdminClicked
    case turnOnFilterClicked
  }

  struct Reducer: FeatureReducer {
    @Dependency(\.filterXpc) var filterXpc
    @Dependency(\.filterExtension) var filterExtension
  }

  struct RootReducer: RootReducing {
    @Dependency(\.api) var api
    @Dependency(\.filterExtension) var filterExtension
  }
}

extension MenuBarFeature.Reducer {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

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

    // TODO: test
    case .menuBar(.refreshRulesClicked):
      return .task {
        await .user(.refreshRules(TaskResult { try await api.refreshUserRules() }))
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
