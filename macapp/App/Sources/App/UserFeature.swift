import ComposableArchitecture
import Foundation
import Gertie
import MacAppRoute

struct UserFeature: Feature {
  struct State: Equatable, Sendable {
    var data: UserData?
    var numTimesUserTokenNotFound = 0
    var downtimePausedUntil: Date?
  }

  enum Action: Sendable, Equatable {
    case updated(previous: UserData?)
    case pauseDowntimeUntil(Date)
    case endDowntimePause
  }

  struct RootReducer {
    typealias Action = AppReducer.Action
    typealias State = AppReducer.State
    @Dependency(\.api) var api
    @Dependency(\.date.now) var now
    @Dependency(\.device) var device
    @Dependency(\.calendar) var calendar
  }
}

extension UserFeature.RootReducer: RootReducing {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    // these websocket messages mean we need to check back in for updated data
    case .websocket(.receivedMessage(.userUpdated)),
         .websocket(.receivedMessage(.unlockRequestUpdated_v2(_, .accepted, _, _))):
      return .exec { [filterVersion = state.filter.version] send in
        await send(.checkIn(
          result: TaskResult { try await api.appCheckIn(filterVersion) },
          reason: .receivedWebsocketMessage
        ))
      }

    case .heartbeat(.everyMinute):
      var effects: [Effect<Action>] = []
      if let blockedApps = state.user.data?.blockedApps, !blockedApps.isEmpty {
        effects.append(.exec { [blockedApps = blockedApps] _ in
          await self.device.terminateBlockedApps(blockedApps)
        })
      }
      if let expiry = state.user.downtimePausedUntil, self.now >= expiry {
        state.user.downtimePausedUntil = nil
      }
      if let downtime = state.user.data?.downtime {
        let minutesTillDowntime = PlainTime.from(self.now, in: self.calendar)
          .minutesUntil(downtime.start)
        switch minutesTillDowntime {
        case 5:
          effects.append(.exec { _ in
            if self.device.currentUserHasScreen(), !self.device.screensaverRunning() {
              await self.device.showNotification(
                "😴 Downtime starting in 5 minutes",
                "Browsers will quit, save any important work now!"
              )
            }
          })
        case 0:
          effects.append(.exec { [browsers = state.browsers] _ in
            await self.device.quitBrowsers(browsers)
          })
        default:
          break
        }
      }
      return .merge(effects)

    case .heartbeat(.everySixHours):
      let timesTokenNotFound = state.user.numTimesUserTokenNotFound
      return timesTokenNotFound >= 8
        ? .exec { send in await send(.history(.userConnection(.disconnectMissingUser))) }
        : .none

    default:
      return .none
    }
  }
}

extension UserFeature {
  struct Reducer: FeatureReducer {
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      .none
    }
  }
}
