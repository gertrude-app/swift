import ComposableArchitecture
import MacAppRoute

struct CheckInFeature {
  struct RootReducer: RootReducing {
    @Dependency(\.api) var api
    @Dependency(\.device) var device
    @Dependency(\.filterXpc) var filterXpc
    @Dependency(\.network) var network
    @Dependency(\.storage) var storage
  }
}

extension CheckInFeature.RootReducer {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    case .heartbeat(.everyTwentyMinutes):
      return checkIn(reason: .heartbeat, notifyNoInternet: false)

    case .menuBar(.refreshRulesClicked),
         .adminWindow(.webview(.healthCheck(.zeroKeysRefreshRulesClicked))):
      return checkIn(reason: .userRefreshedRules)

    case .adminWindow(.webview(.inactiveAccountRecheckClicked)),
         .blockedRequests(.webview(.inactiveAccountRecheckClicked)),
         .requestSuspension(.webview(.inactiveAccountRecheckClicked)):
      return checkIn(reason: .inactiveAccountRechecked)

    case .checkIn(.success(let output), let reason):
      let previousUserData = state.user.data
      state.user.data = output.userData
      state.user.numTimesUserTokenNotFound = 0
      state.appUpdates.latestVersion = output.latestRelease
      state.appUpdates.releaseChannel = output.updateReleaseChannel
      state.admin.accountStatus = output.adminAccountStatus
      return .merge(
        .exec { send in
          await send(.user(.updated(previous: previousUserData)))
        },
        .exec { _ in
          await api.setAccountActive(output.adminAccountStatus == .active)
        },
        .exec { [persist = state.persistent] _ in
          try await storage.savePersistentState(persist)
        },
        .exec { [filterInstalled = state.filter.extension.installed] _ in
          guard filterInstalled else {
            if reason == .userRefreshedRules {
              // if filter was never installed, we don't want to show an error
              // message (or nothing), so consider this a success and notify
              await device.notify("Refreshed rules successfully")
            }
            return
          }

          let sendToFilterResult = await filterXpc.sendUserRules(
            output.appManifest,
            output.keys.map { .init(id: $0.id, key: $0.key) }
          )

          if reason == .userRefreshedRules {
            if sendToFilterResult.isSuccess {
              await device.notify("Refreshed rules successfully")
            } else {
              await device.notify(
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
          await device.notify(
            "Error refreshing rules",
            "Please try again, or contact support if the problem persists."
          )
        }
      }

    default:
      return .none
    }
  }

  func checkIn(reason: CheckIn.Reason, notifyNoInternet: Bool = true) -> Effect<Action> {
    .exec { send in
      if !network.isConnected() {
        if notifyNoInternet {
          await device.notifyNoInternet()
        }
      } else {
        await send(.checkIn(
          result: TaskResult { try await api.appCheckIn() },
          reason: reason
        ))
      }
    }
  }
}

// extensions

extension CheckIn {
  enum Reason: Equatable, Sendable {
    case appLaunched
    case healthCheck
    case heartbeat
    case inactiveAccountRechecked
    case receivedWebsocketMessage
    case userRefreshedRules
  }
}