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

    case .websocket(.receivedMessage(.suspendFilter(let seconds, let comment))):
      return suspendFilter(for: seconds, with: &state, comment: comment)

    case .adminAuthed(.requestSuspension(.webview(.grantSuspensionClicked(let seconds)))):
      state.requestSuspension.windowOpen = false
      return suspendFilter(for: .init(seconds), with: &state)

    case .heartbeat(.everyMinute):
      if let expiration = state.filter.currentSuspensionExpiration, expiration <= now {
        state.filter.currentSuspensionExpiration = nil
      }
      return .none

    case .heartbeat(.everyFiveMinutes):
      return .exec { _ in
        let filter = await filterExtension.state()
        // attempt to reconnect, if necessary
        if filter.isXpcReachable, await xpc.connected() == false {
          _ = await xpc.establishConnection()
        }
      }

    case .menuBar(.resumeFilterClicked):
      state.menuBar.dropdownOpen = false
      state.filter.currentSuspensionExpiration = nil
      return handleFilterSuspensionEnded(early: true)

    case .xpc(.receivedExtensionMessage(.userFilterSuspensionEnded(let userId)))
      where userId == device.currentUserId():
      state.filter.currentSuspensionExpiration = nil
      return handleFilterSuspensionEnded(early: false)

    case .adminWindow(.delegate(.healthCheckFilterExtensionState(let filterState))):
      state.filter.extension = filterState
      return .none

    case .adminAuthed(.adminWindow(.webview(.confirmStopFilterClicked))):
      // big sur (at least) doesn't get a notification pushed through the publisher for this event
      // so optimistically set the extension state, and then recheck after 2 seconds
      state.filter.extension = .installedButNotRunning
      return .exec { send in
        _ = await filterExtension.stop()
        try await mainQueue.sleep(for: .seconds(2))
        await send(.filter(.receivedState(await filterExtension.state())))
      }

    case .menuBar(.turnOnFilterClicked):
      let extensionInstalled = state.filter.extension.installed
      return .merge(
        .exec { send in
          if !extensionInstalled {
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
          } else {
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
        },
        .exec { send in
          // especially for the case of an admin re-starting the stopped extension
          // on Big Sur, the extension state change doesn't get pushed through the publisher
          // so we also poll the state to make sure the admin/user is getting good feedback
          try await mainQueue.sleep(for: .milliseconds(200))
          await send(.filter(.receivedState(await filterExtension.state())))
          for _ in 1 ... 10 {
            try await mainQueue.sleep(for: .seconds(1))
            let state = await filterExtension.state()
            await send(.filter(.receivedState(state)))
            if state == .installedAndRunning { return }
          }
          for _ in 1 ... 10 {
            try await mainQueue.sleep(for: .seconds(5))
            let state = await filterExtension.state()
            await send(.filter(.receivedState(state)))
            if state == .installedAndRunning { return }
          }
        }
      )
    default:
      return .none
    }
  }

  func suspendFilter(
    for seconds: Seconds<Int>,
    with state: inout State,
    comment: String? = nil
  ) -> Effect<Action> {
    state.filter.currentSuspensionExpiration = now.advanced(by: Double(seconds.rawValue))
    return .merge(
      .exec { _ in
        _ = await xpc.suspendFilter(seconds)
      },
      .exec { _ in
        await device.notifyFilterSuspension(resuming: seconds, from: now, with: comment)
      },
      .cancel(id: FilterFeature.CancelId.quitBrowsers)
    )
  }

  func handleFilterSuspensionEnded(early endedEarly: Bool = false) -> Effect<Action> {
    .exec { send in
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
