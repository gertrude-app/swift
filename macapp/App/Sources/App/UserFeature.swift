import ComposableArchitecture
import Gertie
import MacAppRoute

struct UserFeature: Feature {
  typealias State = UserData

  enum Action: Equatable, Sendable {
    case refreshRules(result: TaskResult<RefreshRules.Output>, userInitiated: Bool)
  }

  struct RootReducer {
    @Dependency(\.api) var api
    @Dependency(\.device) var device
    @Dependency(\.filterXpc) var filterXpc
  }

  struct Reducer: FeatureReducer {
    @Dependency(\.device) var device

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      switch action {

      case .refreshRules(.success(let output), _):
        state.screenshotSize = output.screenshotsResolution
        state.screenshotFrequency = output.screenshotsFrequency
        state.keyloggingEnabled = output.keyloggingEnabled
        state.screenshotsEnabled = output.screenshotsEnabled
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
      guard state.user != nil else { return .none }
      return .task {
        await .user(.refreshRules(
          result: TaskResult { try await api.refreshUserRules() },
          userInitiated: false
        ))
      }

    case .websocket(.receivedMessage(.userUpdated)),
         .adminWindow(.webview(.healthCheck(.zeroKeysRefreshRulesClicked))),
         .websocket(.receivedMessage(.unlockRequestUpdated(.accepted, _, _))):
      return .task {
        await .user(.refreshRules(
          result: TaskResult { try await api.refreshUserRules() },
          userInitiated: false
        ))
      }

    case .menuBar(.refreshRulesClicked):
      return .task {
        await .user(.refreshRules(
          result: TaskResult { try await api.refreshUserRules() },
          userInitiated: true
        ))
      }

    case .user(.refreshRules(.success(let output), let userInitiated)):
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
