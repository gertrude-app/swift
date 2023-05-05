import ComposableArchitecture
import Core
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
    @Dependency(\.api) var api
    @Dependency(\.filterXpc) var xpc
    @Dependency(\.filterExtension) var filter
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.storage) var storage
    @Dependency(\.updater) var updater
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
      let channel = state.appUpdates.releaseChannel
      let feedUrl = state.appUpdates.updateFeedUrl
      let persist = state.persistent
      return .run { _ in try await triggerUpdate(channel, feedUrl, persist) }

    case .heartbeat(.everySixHours):
      let current = state.appUpdates.installedVersion
      let channel = state.appUpdates.releaseChannel
      let feedUrl = state.appUpdates.updateFeedUrl
      let persist = state.persistent
      return .run { _ in
        let latest = try await api.latestAppVersion(channel)
        let shouldUpdate: Bool
        if let current = Semver(current), let latest = Semver(latest) {
          shouldUpdate = latest > current
        } else {
          shouldUpdate = latest != current // TODO: log unreachable
        }
        if shouldUpdate {
          try await triggerUpdate(channel, feedUrl, persist)
        }
      }

    default:
      return .none
    }
  }

  func triggerUpdate(
    _ channel: ReleaseChannel,
    _ feedUrl: URL,
    _ persist: Persistent.State
  ) async throws {
    let query = AppcastQuery(channel: channel)
    let feedUrl = "\(feedUrl.absoluteString)\(query.urlString)"
    try await storage.savePersistentState(persist)
    try await updater.triggerUpdate(feedUrl)
  }
}
