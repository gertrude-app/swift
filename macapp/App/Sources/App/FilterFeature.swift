import ClientInterfaces
import ComposableArchitecture
import Core
import Foundation
import TaggedTime

struct FilterFeature: Feature {
  struct State: Equatable {
    var currentSuspensionExpiration: Date?
    var `extension`: FilterExtensionState = .unknown
  }

  enum Action: Equatable, Sendable {
    case receivedState(FilterExtensionState)
  }

  struct Reducer: FeatureReducer {
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      switch action {
      case .receivedState(let extensionState):
        state.extension = extensionState
        return .none
      }
    }
  }

  enum CancelId {
    case quitBrowsers
  }

  struct RootReducer: RootReducing {
    @Dependency(\.date.now) var now
    @Dependency(\.device) var device
    @Dependency(\.filterExtension) var filterExtension
    @Dependency(\.filterXpc) var xpc
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.websocket) var websocket
  }
}

extension FilterFeature.RootReducer {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    case .adminAuthenticated(.adminWindow(.webview(.suspendFilterClicked(let seconds)))):
      return suspendFilter(for: .init(seconds), with: &state)

    case .websocket(.receivedMessage(.suspendFilter(let seconds, let comment))):
      return .merge(
        suspendFilter(for: seconds, with: &state),
        .run { _ in
          await device.notifyFilterSuspension(resuming: seconds, from: now, with: comment)
        }
      )

    case .heartbeat(.everyMinute):
      if let expiration = state.filter.currentSuspensionExpiration, expiration <= now {
        state.filter.currentSuspensionExpiration = nil
      }
      return .none

    case .heartbeat(.everyFiveMinutes):
      return .run { _ in
        let filter = await filterExtension.state()
        // attempt to reconnect, if necessary
        if filter.isXpcReachable, await xpc.connected() == false {
          _ = await xpc.establishConnection()
        }
      }

    case .adminWindow(.webview(.resumeFilterClicked)), .menuBar(.resumeFilterClicked):
      state.filter.currentSuspensionExpiration = nil
      return handleFilterSuspensionEnded(early: true)

    case .xpc(.receivedExtensionMessage(.userFilterSuspensionEnded(let userId)))
      where userId == device.currentUserId():
      state.filter.currentSuspensionExpiration = nil
      return handleFilterSuspensionEnded(early: false)

    case .adminWindow(.delegate(.healthCheckFilterExtensionState(let filterState))):
      state.filter.extension = filterState
      return .none

    case .menuBar(.turnOnFilterClicked),
         .adminWindow(.webview(.startFilterClicked)):
      if !state.filter.extension.installed {
        return .run { send in
          switch await filterExtension.install() {
          case .installedSuccessfully:
            break
          case .timedOutWaiting:
            interestingEvent(id: "9ffabfe5")
            await send(.focusedNotification(.filterInstallTimeout))
          case .userClickedDontAllow:
            await send(.focusedNotification(.filterInstallDenied))
          case .activationRequestFailed(let error):
            unexpectedError(id: "61d0eda0", error)
          case .failedToGetBundleIdentifier:
            unexpectedError(id: "d4a652e9")
          case .failedToLoadConfig:
            unexpectedError(id: "bd04ba1a")
          case .failedToSaveConfig:
            unexpectedError(id: "161ed707")
          case .alreadyInstalled:
            unexpectedError(id: "ff51a770")
          }
        }
      } else {
        return .run { _ in
          switch await filterExtension.start() {
          case .installedAndRunning:
            break
          case .errorLoadingConfig:
            unexpectedError(id: "c291bcef")
          case .installedButNotRunning:
            unexpectedError(id: "99f3465c")
          case .notInstalled:
            unexpectedError(id: "6e4f30ac")
          case .unknown:
            unexpectedError(id: "24f31d4c")
          }
        }
      }
    default:
      return .none
    }
  }

  func suspendFilter(for seconds: Seconds<Int>, with state: inout State) -> Effect<Action> {
    state.filter.currentSuspensionExpiration = now.advanced(by: Double(seconds.rawValue))
    return .merge(
      .run { _ in _ = await xpc.suspendFilter(seconds) },
      .cancel(id: FilterFeature.CancelId.quitBrowsers)
    )
  }

  func handleFilterSuspensionEnded(early endedEarly: Bool = false) -> Effect<Action> {
    .run { send in
      if endedEarly { _ = await xpc.endFilterSuspension() }
      try? await websocket.send(.currentFilterState(.on))
      await device.notifyBrowsersQuitting()
      try await mainQueue.sleep(for: .seconds(60))
      await device.quitBrowsers()
    }
    .cancellable(id: FilterFeature.CancelId.quitBrowsers, cancelInFlight: true)
  }
}

private extension AppReducer.Action.FocusedNotification {
  static var filterInstallTimeout: Self {
    .text(
      "Filter install never completed",
      "Try again, and be sure to allow Gertrude to install a system extension in \"System Settings > Privacy & Security\"."
    )
  }

  static var filterInstallDenied: Self {
    .text(
      "Filter install failed",
      "We couldn't install the filter, you may have refused permission. Please try again, clicking \"Allow\"."
    )
  }
}
