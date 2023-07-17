import ClientInterfaces
import ComposableArchitecture
import Core
import Foundation
import Gertie
import MacAppRoute

struct AppUpdatesFeature: Feature {

  struct State: Equatable {
    var installedVersion: String
    var releaseChannel: ReleaseChannel = .stable
    var latestVersion: LatestAppVersion.Output?
    var updateNagDismissedUntil: Date?
  }

  enum Action: Equatable, Sendable {
    enum Delegate: Equatable, Sendable {
      case postUpdateFilterNotInstalled
      case postUpdateFilterReplaceFailed
    }

    case latestVersionResponse(TaskResult<LatestAppVersion.Output>)
    case delegate(Delegate)
  }

  struct Reducer: FeatureReducer {
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      .none
    }
  }

  struct RootReducer {
    @Dependency(\.api) var api
    @Dependency(\.device) var device
    @Dependency(\.filterXpc) var xpc
    @Dependency(\.filterExtension) var filter
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.network) var network
    @Dependency(\.date.now) var now
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
      return .exec { [new = state.persistent] _ in
        try await storage.savePersistentState(new)
      }

    case .loadedPersistentState(.some(let restored)):
      guard restored.appVersion != state.appUpdates.installedVersion else {
        return .none
      }
      return .merge(
        .exec { [updated = state.persistent] _ in
          try await storage.savePersistentState(updated)
        },
        .exec { send in
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
         .adminWindow(.webview(.reinstallAppClicked)),
         .menuBar(.updateNagUpdateClicked),
         .menuBar(.updateRequiredUpdateClicked):
      state.adminWindow.windowOpen = false // so they can see sparkle update
      state.menuBar.dropdownOpen = false // dismiss menubar overlay nags
      let channel = state.appUpdates.releaseChannel
      let persist = state.persistent
      let force = action == .adminWindow(.webview(.reinstallAppClicked)) ? true : nil
      return .exec { _ in
        if network.isConnected() {
          try await triggerUpdate(channel, persist, force: force)
        } else {
          await device.notifyNoInternet()
        }
      }

    case .appUpdates(.latestVersionResponse(.success(let latest))):
      state.appUpdates.latestVersion = latest
      let current = state.appUpdates.installedVersion
      let channel = state.appUpdates.releaseChannel
      let persist = state.persistent
      let shouldUpdate: Bool
      if let current = Semver(current), let latest = Semver(latest.semver) {
        shouldUpdate = latest > current
      } else {
        shouldUpdate = latest.semver != current
        unexpectedError(id: "bbb7eeba")
      }
      return .exec { _ in
        if shouldUpdate {
          try await triggerUpdate(channel, persist)
        }
      }

    case .heartbeat(.everyHour):
      if let dismissal = state.appUpdates.updateNagDismissedUntil, now > dismissal {
        state.appUpdates.updateNagDismissedUntil = nil
      }
      return .none

    case .heartbeat(.everySixHours):
      let current = state.appUpdates.installedVersion
      let channel = state.appUpdates.releaseChannel
      return .exec { send in
        guard network.isConnected() else { return }
        await send(.appUpdates(.latestVersionResponse(TaskResult {
          try await api.latestAppVersion(.init(
            releaseChannel: channel,
            currentVersion: current
          ))
        })))
      }

    case .adminWindow(.webview(.releaseChannelUpdated(let channel))):
      state.appUpdates.releaseChannel = channel
      return .exec { [updated = state.persistent] _ in
        try await storage.savePersistentState(updated)
      }

    case .adminWindow(.webview(.advanced(.forceUpdateToSpecificVersionClicked(let version)))):
      state.adminWindow.windowOpen = false // so they can see sparkle update
      let persist = state.persistent
      return .exec { _ in
        if network.isConnected() {
          try await triggerUpdate(.init(force: true, version: version), persist)
        } else {
          await device.notifyNoInternet()
        }
      }

    case .menuBar(.updateNagDismissClicked):
      state.appUpdates.updateNagDismissedUntil = now.advanced(by: .hours(26))
      return .none

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
