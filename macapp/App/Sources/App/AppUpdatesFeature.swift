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
    var latestVersion: CheckIn_v2.LatestRelease?
    var updateNagDismissedUntil: Date?
  }

  enum Action: Equatable, Sendable {
    enum Delegate: Equatable, Sendable {
      case postUpdateFilterNotInstalled
      case postUpdateFilterReplaceFailed
      case updateSucceeded(oldVersion: String, newVersion: String)
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
    @Dependency(\.app) var app
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
          try await self.storage.savePersistentState(updated)
        },
        .exec { [newVersion = state.appUpdates.installedVersion] send in
          switch await self.filter.state() {
          case .notInstalled:
            await send(.appUpdates(.delegate(.postUpdateFilterNotInstalled)))
          default:
            try await replaceFilter(send)
            if await self.xpc.notConnected() {
              await self.api.securityEvent(.appUpdateFailedToReplaceSystemExtension)
              await send(.appUpdates(.delegate(.postUpdateFilterReplaceFailed)))
              await unexpectedError(id: "cde231a0", detail: "state: \(self.filter.state())")
            } else {
              await self.api.securityEvent(.appUpdateSucceeded)
              await send(.appUpdates(.delegate(.updateSucceeded(
                oldVersion: restored.appVersion,
                newVersion: newVersion
              ))))

              // refresh the rules post-update, or else health check will complain
              await send(.checkIn(
                result: TaskResult { try await self.api.appCheckIn(newVersion) },
                reason: .appUpdated
              ))

              // big sur doesn't get notification pushed when filter restarts
              // so check manually after attempting to replace the filter
              try await self.mainQueue.sleep(for: .seconds(1))
              await send(.filter(.receivedState(self.filter.state())))
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
        if self.network.isConnected() {
          try await self.triggerUpdate(channel, persist)
        } else {
          await self.device.notifyNoInternet()
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
          try await self.triggerUpdate(channel, persist)
        }
      }

    case .heartbeat(.everyHour):
      if let dismissal = state.appUpdates.updateNagDismissedUntil, self.now > dismissal {
        state.appUpdates.updateNagDismissedUntil = nil
      }
      return .none

    case .adminWindow(.webview(.advanced(.forceUpdateToSpecificVersionClicked(let version)))):
      state.adminWindow.windowOpen = false // so they can see sparkle update
      let persist = state.persistent
      return .exec { _ in
        if self.network.isConnected() {
          try await self.triggerUpdate(
            .init(force: true, version: version, requestingAppVersion: persist.appVersion),
            persist
          )
        } else {
          await self.device.notifyNoInternet()
        }
      }

    case .menuBar(.updateNagDismissClicked):
      state.appUpdates.updateNagDismissedUntil = self.now.advanced(by: .hours(26))
      return .none

    case .appUpdates(.delegate(.updateSucceeded(let old, _))):
      guard (Semver(old) ?? .zero) < .init("2.6.3")! else {
        return .none
      }
      return .exec { send in
        guard self.device.osVersion().major > 10 else {
          // catalina doesn't autorestart, and very unlikely they'll ever get to 15.x
          return
        }
        if await self.app.hasFullDiskAccess() == false {
          await send(.onboarding(.delegate(.openForUpgrade(
            step: .allowFullDiskAccess_grantAndRestart
          ))))
        }
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
    let query = AppcastQuery(
      channel: channel,
      force: force,
      requestingAppVersion: persist.appVersion
    )
    try await self.triggerUpdate(query, persist)
  }

  func triggerUpdate(
    _ query: AppcastQuery,
    _ persist: Persistent.State
  ) async throws {
    let feedUrl = "\(self.updater.endpoint.absoluteString)\(query.urlString)"
    try await self.storage.savePersistentState(persist)
    try await self.updater.triggerUpdate(feedUrl)
  }

  func afterFilterChange(_ send: Send<Action>, repairing: Bool) async {
    // noop. NB: providing this noop as a default protocol implementation caused problems
  }
}
