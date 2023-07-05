import ComposableArchitecture
import Gertie
import MacAppRoute

struct UserFeature: Feature {
  struct State: Equatable, Sendable {
    var data: UserData
    var numTimesUserTokenNotFound = 0
  }

  enum Action: Equatable, Sendable {
    case refreshRules(result: TaskResult<RefreshRules.Output>, userInitiated: Bool)
  }

  struct RootReducer {
    @Dependency(\.api) var api
    @Dependency(\.device) var device
    @Dependency(\.filterXpc) var filterXpc
    @Dependency(\.network) var network
  }

  struct Reducer: FeatureReducer {
    @Dependency(\.device) var device

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      switch action {

      case .refreshRules(.success(let output), _):
        state.data.screenshotSize = output.screenshotsResolution
        state.data.screenshotFrequency = output.screenshotsFrequency
        state.data.keyloggingEnabled = output.keyloggingEnabled
        state.data.screenshotsEnabled = output.screenshotsEnabled
        return .none

      case .refreshRules(result: .failure, userInitiated: true):
        return .run { _ in
          await device.showNotification(
            "Error refreshing rules",
            "Please try again, or contact support if the problem persists."
          )
        }

      case .refreshRules(result: .failure, userInitiated: false):
        return .none
      }
    }
  }
}

extension UserFeature.RootReducer: RootReducing {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    case .heartbeat(.everyTwentyMinutes):
      guard state.user != nil, network.isConnected() else { return .none }
      return .task {
        await .user(.refreshRules(
          result: TaskResult { try await api.refreshUserRules() },
          userInitiated: false
        ))
      }

    case .websocket(.receivedMessage(.userUpdated)),
         .websocket(.receivedMessage(.unlockRequestUpdated(.accepted, _, _))):
      return .task {
        await .user(.refreshRules(
          result: TaskResult { try await api.refreshUserRules() },
          userInitiated: false
        ))
      }

    case .adminWindow(.webview(.healthCheck(.zeroKeysRefreshRulesClicked))):
      return .run { send in
        if !network.isConnected() {
          await device.notifyNoInternet()
        } else {
          await send(.user(.refreshRules(
            result: TaskResult { try await api.refreshUserRules() },
            userInitiated: false
          )))
        }
      }

    case .menuBar(.refreshRulesClicked):
      return .run { send in
        if !network.isConnected() {
          await device.notifyNoInternet()
        } else {
          await send(.user(.refreshRules(
            result: TaskResult { try await api.refreshUserRules() },
            userInitiated: true
          )))
        }
      }

    case .user(.refreshRules(.failure(let err), false)):
      if let pqlError = err as? PqlError, pqlError.appTag == .userTokenNotFound {
        state.user?.numTimesUserTokenNotFound += 1
      }
      let timesTokenNotFound = state.user?.numTimesUserTokenNotFound ?? 0
      return timesTokenNotFound > 4 ? .run { send in
        await send(.history(.userConnection(.disconnectMissingUser)))
      } : .none

    case .user(.refreshRules(.success(let output), let userInitiated)):
      state.user?.numTimesUserTokenNotFound = 0
      return .run { [filterInstalled = state.filter.extension.installed] _ in
        guard filterInstalled else {
          if userInitiated {
            // if filter was never installed, we don't want to show an error
            // message (or nothing), so consider this a success and notify
            await device.showNotification("Refreshed rules successfully", "")
          }
          return
        }

        let sendToFilterResult = await filterXpc.sendUserRules(
          output.appManifest,
          output.keys.map { .init(id: $0.id, key: $0.key) }
        )

        if userInitiated {
          if sendToFilterResult.isSuccess {
            await device.showNotification("Refreshed rules successfully", "")
          } else {
            await device.showNotification(
              "Error refreshing rules",
              "We got updated rules, but there was an error sending them to the filter."
            )
          }
        }
      }

    default:
      return .none
    }
  }
}
