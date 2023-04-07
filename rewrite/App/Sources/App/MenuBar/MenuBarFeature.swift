import ComposableArchitecture

// TODO: remove `public` modifiers when doing codegen
// from test target instead of cli

public enum MenuBarFeature: Feature {
  public enum State: Equatable, Encodable {
    public struct Connected: Equatable {
      public enum FilterState: Equatable, Codable {
        case off
        case on
        case suspended(expiration: String)
      }

      public var filterState: FilterState
      public var recordingScreen: Bool
      public var recordingKeystrokes: Bool
    }

    case notConnected
    case enteringConnectionCode
    case connecting
    case connectionFailed(error: String)
    case connectionSucceded(userName: String)
    case connected(Connected)
  }

  public enum Action: Equatable, Decodable, Sendable {
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
    @Dependency(\.app) var appClient
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
        await .user(.refreshRules(TaskResult {
          let appVersion = appClient.installedVersion() ?? "unknown"
          return try await api.refreshRules(.init(appVersion: appVersion))
        }))
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
