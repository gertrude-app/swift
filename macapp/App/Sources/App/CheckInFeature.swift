import ComposableArchitecture
import Core
import Foundation
import MacAppRoute

enum CheckInFeature {
  struct RootReducer: RootReducing {
    typealias Action = AppReducer.Action
    typealias State = AppReducer.State
    @Dependency(\.api) var api
    @Dependency(\.date.now) var now
    @Dependency(\.device) var device
    @Dependency(\.filterXpc) var filterXpc
    @Dependency(\.network) var network
    @Dependency(\.storage) var storage
  }
}

extension CheckInFeature.RootReducer {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    case .heartbeat(.everyTwentyMinutes) where state.admin.accountStatus != .inactive:
      return self.checkIn(reason: .heartbeat, state: state)

    case .heartbeat(.everySixHours) where state.admin.accountStatus == .inactive:
      return self.checkIn(reason: .heartbeat, state: state)

    case .heartbeat(.everyMinute) where
      state.requestSuspension.pending != nil
      || !state.blockedRequests.pendingUnlockRequests.isEmpty:
      return self.checkIn(reason: .pendingRequest, state: state)

    case .menuBar(.refreshRulesClicked),
         .adminWindow(.webview(.healthCheck(.zeroKeysRefreshRulesClicked))):
      return self.checkIn(reason: .userRefreshedRules, state: state)

    case .adminWindow(.webview(.inactiveAccountRecheckClicked)),
         .blockedRequests(.webview(.inactiveAccountRecheckClicked)),
         .requestSuspension(.webview(.inactiveAccountRecheckClicked)):
      return self.checkIn(reason: .inactiveAccountRechecked, state: state)

    case .checkIn(.success(let output), let reason):
      guard output.adminAccountStatus != .inactive else {
        state.admin.accountStatus = output.adminAccountStatus
        return .exec { _ in await self.api.setAccountActive(false) }
      }
      let previousUserData = state.user.data
      state.user.data = output.userData
      state.user.numTimesUserTokenNotFound = 0
      state.appUpdates.latestVersion = output.latestRelease
      state.appUpdates.releaseChannel = output.updateReleaseChannel
      state.admin.accountStatus = output.adminAccountStatus
      state.browsers = output.browsers
      return .merge(
        .exec { send in
          await send(.user(.updated(previous: previousUserData)))
        },
        .exec { _ in
          await api.setAccountActive(output.adminAccountStatus == .active)
        },
        .exec { [persist = state.persistent] _ in
          try await self.storage.savePersistentState(persist)
        },
        .exec { send in
          let system = self.now
          if let boottime = self.device.boottime() {
            await send(.setTrustedTimestamp(.init(
              network: Date(timeIntervalSince1970: output.trustedTime),
              system: system,
              boottime: boottime
            )))
          }
        },
        .exec { [
          filterInstalled = state.filter.extension.installed,
          downtimePausedUntil = state.user.downtimePausedUntil
        ] _ in
          guard filterInstalled else {
            if reason == .userRefreshedRules {
              // if filter was never installed, we don't want to show an error
              // message (or nothing), so consider this a success and notify
              await self.device.notify("Refreshed rules successfully")
            }
            return
          }

          let sendToFilterResult = await self.filterXpc.sendUserRules(
            output.appManifest,
            output.keychains,
            output.userData.downtime.map {
              Downtime(window: $0, pausedUntil: downtimePausedUntil)
            }
          )

          if case .some(let suspension) = output.resolvedFilterSuspension,
             suspension.decision != .rejected {
            return // only show the suspension notification
          }

          if reason == .userRefreshedRules {
            if sendToFilterResult.isSuccess {
              await self.device.notify("Refreshed rules successfully")
            } else {
              await self.device.notify(
                "Error refreshing rules",
                "We got updated rules, but there was an error sending them to the filter."
              )
            }
          }
        }
      )

    case .checkIn(result: .failure(let err), reason: let reason):
      if let pqlError = err as? PqlError, pqlError.appTag == .userTokenNotFound {
        state.user.numTimesUserTokenNotFound += 1
      }
      return .exec { _ in
        if reason == .userRefreshedRules {
          await self.device.notify(
            "Error refreshing rules",
            "Please try again, or contact support if the problem persists."
          )
        }
      }

    default:
      return .none
    }
  }

  func checkIn(reason: CheckIn.Reason, state: State) -> Effect<Action> {
    .exec { send in
      if !network.isConnected() {
        if reason == .userRefreshedRules {
          await self.device.notifyNoInternet()
        }
      } else {
        await send(.checkIn(
          result: TaskResult {
            try await api.appCheckIn(
              state.filter.version,
              pendingFilterSuspension: state.requestSuspension.pending?.id,
              pendingUnlockRequests: state.blockedRequests.pendingUnlockRequests.map(\.id),
              sendNamedApps: reason == .heartbeat
            )
          },
          reason: reason
        ))
      }
    }
  }
}

// extensions

extension CheckIn {
  enum Reason: Equatable, Sendable {
    case appUpdated
    case healthCheck
    case heartbeat
    case startProtecting
    case inactiveAccountRechecked
    case receivedWebsocketMessage
    case userRefreshedRules
    case pendingRequest
  }
}
