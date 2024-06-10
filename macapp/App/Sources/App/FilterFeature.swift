import ClientInterfaces
import ComposableArchitecture
import Core
import Foundation
import Gertie
import os.log
import TaggedTime

struct FilterFeature: Feature {
  struct State: Equatable {
    var currentSuspensionExpiration: Date?
    var `extension`: FilterExtensionState
    var version: String
  }

  enum Action: Equatable, Sendable {
    case receivedState(FilterExtensionState)
    case receivedVersion(String)
    case replacedFilterVersion(String)
  }

  struct Reducer: FeatureReducer {
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      switch action {
      case .receivedState(let extensionState):
        state.extension = extensionState
        return .none

      case .receivedVersion(let version),
           .replacedFilterVersion(let version):
        state.version = version
        return .none
      }
    }
  }

  enum CancelId {
    case quitBrowsers
  }

  struct RootReducer: RootReducing {
    typealias Action = AppReducer.Action
    typealias State = AppReducer.State
    @Dependency(\.api) var api
    @Dependency(\.app) var app
    @Dependency(\.date.now) var now
    @Dependency(\.device) var device
    @Dependency(\.filterExtension) var filterExtension
    @Dependency(\.filterXpc) var xpc
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.storage) var storage
    @Dependency(\.websocket) var websocket
  }
}

extension FilterFeature.State {
  init(appVersion: String?) {
    self.init(
      currentSuspensionExpiration: nil,
      extension: .unknown,
      version: appVersion ?? "unknown"
    )
  }

  var filterState: FilterState {
    FilterState(
      extensionState: self.extension,
      currentSuspensionExpiration: currentSuspensionExpiration
    )
  }

  var isSuspended: Bool {
    self.filterState.isSuspended
  }
}

extension FilterFeature.RootReducer {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    case .websocket(.receivedMessage(.filterSuspensionRequestDecided(
      .accepted(let seconds, let extraMonitoring),
      let comment
    ))):
      return self.suspendFilter(
        for: seconds,
        with: &state,
        comment: comment,
        extraMonitoring: extraMonitoring != nil
      )

    case .websocket(.receivedMessage(.filterSuspensionRequestDecided(.rejected, let comment))):
      return .exec { _ in
        await device.notifyFilterSuspensionDenied(with: comment)
      }

    case .websocket(.receivedMessage(.suspendFilter(let seconds, let comment))):
      unexpectedError(id: "64635783") // api should not send this legacy event
      return self.suspendFilter(for: seconds, with: &state, comment: comment)

    case .adminAuthed(.requestSuspension(.webview(.grantSuspensionClicked(let seconds)))):
      state.requestSuspension.windowOpen = false
      return self.suspendFilter(for: .init(seconds), with: &state, fromAdmin: true)

    case .heartbeat(.everyMinute):
      if let expiration = state.filter.currentSuspensionExpiration, expiration <= now {
        state.filter.currentSuspensionExpiration = nil
      }
      return .none

    case .heartbeat(.everyFiveMinutes):
      let appVersionString = state.appUpdates.installedVersion
      return .exec { [persist = state.persistent] send in
        let filter = await filterExtension.state()
        guard filter.isXpcReachable else { return }
        // attempt to reconnect, if necessary
        if await xpc.connected() == false {
          _ = await xpc.establishConnection()
        } else if case .success(let acc) = await xpc.requestAck() {
          await send(.filter(.receivedVersion(acc.version)))

          // if the filter is ahead, another user must have updated Gertrude
          // so we need to relaunch to get on the same version w/ the filter
          if let filterVersion = Semver(acc.version),
             let appVersion = Semver(appVersionString),
             filterVersion > appVersion {
            os_log(
              "[G•] APP relaunch, filter ahead: `%{public}s` > `%{public}s`",
              acc.version, appVersionString
            )
            try await storage.savePersistentState(persist)
            await app.stopRelaunchWatcher()
            try await app.relaunch()
          }
        }
      }

    case .menuBar(.resumeFilterClicked):
      state.menuBar.dropdownOpen = false
      state.filter.currentSuspensionExpiration = nil
      return self.handleFilterSuspensionEnded(browsers: state.browsers, early: true)

    case .xpc(.receivedExtensionMessage(.userFilterSuspensionEnded(let userId)))
      where userId == device.currentUserId():
      state.filter.currentSuspensionExpiration = nil
      return self.handleFilterSuspensionEnded(browsers: state.browsers, early: false)

    case .adminWindow(.delegate(.healthCheckFilterExtensionState(let filterState))):
      state.filter.extension = filterState
      return .none

    case .adminAuthed(.adminWindow(.webview(.confirmStopFilterClicked))):
      // big sur (at least) doesn't get a notification pushed through the publisher for this event
      // so optimistically set the extension state, and then recheck after 2 seconds
      state.filter.extension = .installedButNotRunning
      return .exec { send in
        await api.securityEvent(.systemExtensionChanged, "stop")
        _ = await filterExtension.stop()
        try await mainQueue.sleep(for: .seconds(2))
        await send(.filter(.receivedState(await filterExtension.state())))
      }

    case .menuBar(.turnOnFilterClicked):
      let extensionInstalled = state.filter.extension.installed
      return .merge(
        .exec { send in
          if !extensionInstalled {
            await api.securityEvent(.systemExtensionChanged, "install")
            let installResult = await filterExtension.install()
            switch installResult {
            case .installedSuccessfully:
              break
            case .timedOutWaiting:
              // event `9ffabfe5` logged w/ more detail in FilterFeature.swift
              await send(.focusedNotification(.filterInstallTimeout))
            case .userClickedDontAllow:
              interestingEvent(id: "01f94ff3")
              await send(.focusedNotification(.filterInstallDenied))
            case .activationRequestFailed,
                 .failedToGetBundleIdentifier,
                 .failedToLoadConfig,
                 .failedToSaveConfig,
                 .alreadyInstalled:
              unexpectedError(id: "8a8762e7", detail: "result: \(installResult)")
            }
          } else {
            await api.securityEvent(.systemExtensionChanged, "start")
            let state = await filterExtension.start()
            switch state {
            case .installedAndRunning:
              break
            case .errorLoadingConfig,
                 .installedButNotRunning,
                 .notInstalled,
                 .unknown:
              unexpectedError(id: "cb2a0564", detail: "state: \(state)")
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
    fromAdmin: Bool = false,
    comment: String? = nil,
    extraMonitoring: Bool = false
  ) -> Effect<Action> {
    state.filter.currentSuspensionExpiration = now.advanced(by: Double(seconds.rawValue))
    return .merge(
      .exec { _ in
        _ = await xpc.suspendFilter(seconds)
      },
      .exec { _ in
        await device.notifyFilterSuspension(
          resuming: seconds,
          from: now,
          with: comment,
          extraMonitoring: extraMonitoring
        )
      },
      .exec { _ in
        await api.securityEvent(
          fromAdmin
            ? .filterSuspensionGrantedByAdmin
            : .filterSuspendedRemotely
        )
      },
      .cancel(id: FilterFeature.CancelId.quitBrowsers)
    )
  }

  func handleFilterSuspensionEnded(
    browsers: [BrowserMatch],
    early endedEarly: Bool = false
  ) -> Effect<Action> {
    .exec { send in
      if endedEarly { _ = await xpc.endFilterSuspension() }
      await api.securityEvent(endedEarly ? .filterSuspensionEndedEarly : .filterSuspensionExpired)
      try? await websocket.send(.currentFilterState(.on))
      await device.notifyBrowsersQuitting()
      try await mainQueue.sleep(for: .seconds(60))
      await device.quitBrowsers(browsers)
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
