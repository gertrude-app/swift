import ClientInterfaces
import ComposableArchitecture
import Core
import Foundation
import Gertie

struct AppUpdatesFeature: Feature {

  struct State: Equatable {
    var installedVersion: String
    var releaseChannel: ReleaseChannel = .stable
    var latestVersion: String?
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

    // don't need admin challenge, because sparkle can't update w/out admin auth
    case .adminWindow(.delegate(.triggerAppUpdate)),
         .adminWindow(.webview(.checkForAppUpdatesClicked)),
         .adminWindow(.webview(.reinstallAppClicked)):
      state.adminWindow.windowOpen = false // so they can see sparkle update
      let channel = state.appUpdates.releaseChannel
      let persist = state.persistent
      let force = action == .adminWindow(.webview(.reinstallAppClicked)) ? true : nil
      return .run { _ in
        try await triggerUpdate(channel, persist, force: force)
      }

    case .heartbeat(.everySixHours):
      let current = state.appUpdates.installedVersion
      let channel = state.appUpdates.releaseChannel
      let persist = state.persistent
      return .run { _ in
        let latest = try await api.latestAppVersion(channel)
        let shouldUpdate: Bool
        if let current = Semver(current), let latest = Semver(latest) {
          shouldUpdate = latest > current
        } else {
          shouldUpdate = latest != current
          unexpectedError(id: "bbb7eeba")
        }
        if shouldUpdate {
          try await triggerUpdate(channel, persist)
        }
      }

    case .adminWindow(.webview(.releaseChannelUpdated(let channel))):
      state.appUpdates.releaseChannel = channel
      return .run { [updated = state.persistent] _ in
        try await storage.savePersistentState(updated)
      }

    case .adminWindow(.webview(.advanced(.forceUpdateToSpecificVersionClicked(let version)))):
      state.adminWindow.windowOpen = false // so they can see sparkle update
      let persist = state.persistent
      return .run { _ in
        try await triggerUpdate(.init(force: true, version: version), persist)
      }

    default:
      return .none
    }
  }

  func triggerUpdate(
    _ channel: ReleaseChannel,
    _ persist: Persistent.State,
    force: Bool? = nil
  ) async throws {
    let query = AppcastQuery(channel: channel, force: force)
    try await triggerUpdate(query, persist)
  }

  func triggerUpdate(
    _ query: AppcastQuery,
    _ persist: Persistent.State
  ) async throws {
    let feedUrl = "\(updater.endpoint.absoluteString)\(query.urlString)"
    try await storage.savePersistentState(persist)
    try await updater.triggerUpdate(feedUrl)
  }
}
