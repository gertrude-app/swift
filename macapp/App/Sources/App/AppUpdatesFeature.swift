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
    var latestVersion: CheckIn.LatestRelease?
    var updateNagDismissedUntil: Date?
  }

  enum Action: Equatable, Sendable {
    enum Delegate: Equatable, Sendable {
      case postUpdateFilterNotInstalled
      case postUpdateFilterReplaceFailed
    }

    case delegate(Delegate)
  }

  struct Reducer: FeatureReducer {
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      .none
    }
  }

  struct RootReducer {
    typealias Action = AppReducer.Action
    typealias State = AppReducer.State
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
  init(installedVersion: String?) {
    self.init(
      installedVersion: installedVersion ?? "0.0.0",
      releaseChannel: .stable,
      latestVersion: nil
    )
  }
}

extension AppUpdatesFeature.RootReducer: FilterControlling {

  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    case .loadedPersistentState(.some(let restored)):
      guard restored.appVersion != state.appUpdates.installedVersion else {
        return .none
      }
      return .merge(
        .exec { [updated = state.persistent] _ in
          try await storage.savePersistentState(updated)
        },
        .exec { [version = state.appUpdates.installedVersion] send in
          switch await filter.state() {
          case .notInstalled:
            await send(.appUpdates(.delegate(.postUpdateFilterNotInstalled)))
          default:
            try await replaceFilter(send)
            if await xpc.notConnected() {
              await send(.appUpdates(.delegate(.postUpdateFilterReplaceFailed)))
              unexpectedError(id: "cde231a0", detail: "state: \(await filter.state())")
            } else {
              await send(.filter(.replacedFilterVersion(version)))

              // refresh the rules post-update, or else health check will complain
              await send(.checkIn(
                result: TaskResult { try await api.appCheckIn(version) },
                reason: .appUpdated
              ))

              // big sur doesn't get notification pushed when filter restarts
              // so check manually after attempting to replace the filter
              try await mainQueue.sleep(for: .seconds(1))
              await send(.filter(.receivedState(await filter.state())))
            }
          }
        }
      )

    // don't need admin challenge, because sparkle can't update w/out admin auth
    case .adminWindow(.delegate(.triggerAppUpdate)),
         .adminWindow(.webview(.updateAppNowClicked)),
         .menuBar(.updateNagUpdateClicked),
         .menuBar(.updateRequiredUpdateClicked):
      state.adminWindow.windowOpen = false // so they can see sparkle update
      state.menuBar.dropdownOpen = false // dismiss menubar overlay nags
      let channel = state.appUpdates.releaseChannel
      let persist = state.persistent
      return .exec { _ in
        if network.isConnected() {
          try await triggerUpdate(channel, persist)
        } else {
          await device.notifyNoInternet()
        }
      }

    // every 20 minutes we get updated latest version info from heartbeat check-in,
    // but we want to prompt them to update at most every 6 hours
    case .heartbeat(.everySixHours):
      guard let latest = state.appUpdates.latestVersion else { return .none }
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

  func afterFilterChange(_ send: Send<Action>, repairing: Bool) async {
    // noop. NB: providing this noop as a default protocol implementation caused problems
  }
}
