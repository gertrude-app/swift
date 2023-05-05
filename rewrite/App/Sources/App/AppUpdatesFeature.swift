import ComposableArchitecture
import Foundation
import Shared

struct AppUpdatesFeature: Feature {

  struct State: Equatable {
    var installedVersion: String
    var releaseChannel: ReleaseChannel = .stable // todo, should persist
    var latestVersion: String?

    #if DEBUG
      var updateFeedUrl = URL(string: "http://127.0.0.1:8080/appcast.xml")!
    #else
      var updateFeedUrl = URL(string: "https://api.gertrude.app/appcast.xml")!
    #endif
  }

  enum Action: Equatable, Sendable {
    enum Delegate: Equatable, Sendable {
      case postUpdateFilterNotInstalled
      case postUpdateFilterReplaceFailed
    }

    case latestVersionResponse(TaskResult<String>)
    case delegate(Delegate)
  }

  struct Reducer: FeatureReducer {
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      switch action {

      case .latestVersionResponse(.success(let version)):
        state.latestVersion = version
        return .none

      case .latestVersionResponse(.failure):
        return .none

      case .delegate:
        return .none
      }
    }
  }

  struct RootReducer {
    @Dependency(\.updater) var updater
    @Dependency(\.storage) var storage
    @Dependency(\.filterXpc) var xpc
    @Dependency(\.filterExtension) var filter
    @Dependency(\.mainQueue) var mainQueue
  }
}

extension AppUpdatesFeature.State {
  init() {
    @Dependency(\.app) var appClient
    self.init(
      installedVersion: appClient.installedVersion() ?? "0.0.0",
      releaseChannel: .stable,
      latestVersion: nil
    )
  }
}

extension AppUpdatesFeature.RootReducer: FilterControlling {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .loadedPersistentState(.none):
      return .run { [new = state.persistent] _ in
        try await storage.savePersistentState(new)
      }

    case .loadedPersistentState(.some(let restored)):
      guard restored.appVersion != state.appUpdates.installedVersion else {
        return .none
      }
      return .merge(
        .run { [updated = state.persistent] _ in
          try await storage.savePersistentState(updated)
        },
        .run { send in
          switch await filter.state() {
          case .notInstalled:
            await send(.appUpdates(.delegate(.postUpdateFilterNotInstalled)))
          default:
            try await replaceFilter(send, retryOnce: true)
            if await xpc.notConnected() {
              await send(.appUpdates(.delegate(.postUpdateFilterReplaceFailed)))
            }
          }
        }
      )

    case .adminWindow(.delegate(.triggerAppUpdate)):
      let query = AppcastQuery(channel: state.appUpdates.releaseChannel)
      let feedUrl = "\(state.appUpdates.updateFeedUrl.absoluteString)\(query.urlString)"
      return .run { [beforeUpdate = state.persistent] _ in
        try await storage.savePersistentState(beforeUpdate)
        try await updater.triggerUpdate(feedUrl)
      }

    default:
      return .none
    }
  }
}
