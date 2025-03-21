import ComposableArchitecture
import Foundation
import Gertie
import MacAppRoute

enum MonitoringFeature: Feature {
  struct State: Equatable, Sendable {
    var suspensionMonitoring: UserMonitoringConfig?
    var lastSuspensionMonitoring: UserMonitoringConfig?
  }

  enum Action: Equatable {
    case timerTriggeredTakeScreenshot
  }

  struct Reducer: FeatureReducer {
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      .none
    }
  }

  struct RootReducer: RootReducing {
    typealias Action = AppReducer.Action
    typealias State = AppReducer.State
    @Dependency(\.api) var api
    @Dependency(\.date.now) var now
    @Dependency(\.backgroundQueue) var bgQueue
    @Dependency(\.device) var device
    @Dependency(\.monitoring) var monitoring
    @Dependency(\.network) var network
    @Dependency(\.userDefaults) var userDefaults
  }
}

private enum CancelId {
  case screenshots
}

extension MonitoringFeature.RootReducer {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    case .loadedPersistentState(.some(let stored)):
      guard stored.resumeOnboarding == nil ||
        stored.resumeOnboarding == .checkingFullDiskAccessPermission(upgrade: true) else {
        return .none
      }
      return self.configureMonitoring(current: stored.user, previous: nil)

    case .user(.updated(let previous)):
      return self.configureMonitoring(current: state.user.data, previous: previous)

    case .history(.userConnection(.connect(.success(let user)))):
      return self.configureMonitoring(current: user, previous: nil)

    case .onboarding(.delegate(.onboardingConfigComplete)):
      return self.configureMonitoring(current: state.user.data, previous: nil)

    case .monitoring(.timerTriggeredTakeScreenshot):
      let width = state.user.data?.screenshotSize ?? 800
      let filterSuspended = state.isFilterSuspended
      return .exec { _ in
        try await monitoring.takeScreenshot(width)
        guard network.isConnected() else { return }
        for image in await monitoring.takePendingScreenshots() {
          _ = try await api.uploadScreenshot(.init(
            image: image.data,
            width: image.width,
            height: image.height,
            filterSuspended: filterSuspended,
            createdAt: image.createdAt
          ))
        }
      }

    case .adminAuthed(.requestSuspension(.webview(.grantSuspensionClicked))):
      guard let user = state.user.data,
            let lastMonitoring = state.monitoring.lastSuspensionMonitoring else {
        return .none
      }
      // reuse the last extra suspension monitoring sent via the dashboard
      state.monitoring.suspensionMonitoring = lastMonitoring
      state.monitoring.lastSuspensionMonitoring = lastMonitoring
      return self.configureMonitoring(current: lastMonitoring, previous: user)

    case .websocket(.receivedMessage(let message)):
      switch message {
      case .filterSuspensionRequestDecided_v2(_, .accepted(_, .none), _):
        state.monitoring.lastSuspensionMonitoring = nil
        return .none

      case .filterSuspensionRequestDecided_v2(_, .accepted(_, .some(let extraMonitoring)), _):
        guard let user = state.user.data else { return .none }
        let suspensionMonitoring = user.monitoring(merging: extraMonitoring)
        state.monitoring.suspensionMonitoring = suspensionMonitoring
        state.monitoring.lastSuspensionMonitoring = suspensionMonitoring
        return self.configureMonitoring(current: suspensionMonitoring, previous: user)

      case .userDeleted:
        return .cancel(id: CancelId.screenshots)

      default:
        return .none
      }

    case .checkIn(result: .success(let output), reason: _):
      if let resolvedSuspension = output.resolvedFilterSuspension,
         let user = state.user.data,
         case .accepted(_, let extraMonitoring) = resolvedSuspension.decision {
        if let extraMonitoring {
          let suspensionMonitoring = output.userData.monitoring(merging: extraMonitoring)
          state.monitoring.suspensionMonitoring = suspensionMonitoring
          state.monitoring.lastSuspensionMonitoring = suspensionMonitoring
          return self.configureMonitoring(current: suspensionMonitoring, previous: user)
        } else {
          state.monitoring.lastSuspensionMonitoring = nil
        }
      }
      return .none

    case .heartbeat(.everyFiveMinutes):
      // for simplicity's sake, we ALWAYS try to upload any pending keystrokes
      // so we don't have to worry about edge cases when we stop/restart.
      // if we're not monitoring keystrokes, nothing will go to api
      let flushPendingKeystrokes = self.flushKeystrokes(state.isFilterSuspended)

      // failsafe for cleaning up suspension monitoring if we missed the expiration
      if let suspensionMonitoring = state.monitoring.suspensionMonitoring,
         (state.filter.currentSuspensionExpiration ?? .distantPast) < now {
        state.monitoring.suspensionMonitoring = nil
        return .merge(
          self.configureMonitoring(current: state.user.data, previous: suspensionMonitoring),
          flushPendingKeystrokes
        )
      }
      return flushPendingKeystrokes

    case .heartbeat(.everyTwentyMinutes) where state.admin.accountStatus != .inactive:
      return .exec { _ in
        let users = try await self.device.listMacOSUsers()
        let prevNum = self.userDefaults.getInt("numMacOsUsers")
        if users.count != prevNum {
          self.userDefaults.setInt("numMacOsUsers", users.count)
        }
        // 0 means it's the first time we've checked, nil is coerced to 0
        if prevNum != 0, users.count > prevNum {
          await self.api.securityEvent(.newMacOsUserCreated)
        }
      }

    case .application(.willSleep),
         .adminAuthed(.adminWindow(.webview(.confirmQuitAppClicked))):
      return self.flushKeystrokes(state.isFilterSuspended)

    case .delegate(.filterSuspendedChanged(let wasSuspended, _)):
      if wasSuspended, let suspensionMonitoring = state.monitoring.suspensionMonitoring {
        state.monitoring.suspensionMonitoring = nil
        return .merge(
          self.configureMonitoring(current: state.user.data, previous: suspensionMonitoring),
          self.flushKeystrokes(wasSuspended)
        )
      }
      return self.flushKeystrokes(wasSuspended)

    case .application(.willTerminate):
      return .merge(
        .cancel(id: CancelId.screenshots),
        self.flushKeystrokes(state.isFilterSuspended)
      )

    case .adminAuthed(.adminWindow(.webview(.disconnectUserClicked))),
         .history(.userConnection(.disconnectMissingUser)):
      return .cancel(id: CancelId.screenshots)

    // try to catch the moment when they've fixed monitoring permissions issues
    case .adminWindow(.webview(.healthCheck(.recheckClicked))):
      return self.configureMonitoring(current: state.user.data, previous: nil, force: true)

    default:
      return .none
    }
  }

  func flushKeystrokes(_ filterSuspended: Bool) -> Effect<Action> {
    .exec { _ in
      await monitoring.commitPendingKeystrokes(filterSuspended)
      guard network.isConnected(),
            let keystrokes = await monitoring.takePendingKeystrokes() else { return }
      do {
        try await api.createKeystrokeLines(keystrokes)
      } catch {
        await monitoring.restorePendingKeystrokes(keystrokes)
        throw error
      }
    }
  }

  func configureMonitoring(
    current currentConfig: MonitoringConfig?,
    previous previousConfig: MonitoringConfig?,
    force: Bool = false
  ) -> Effect<Action> {
    switch (currentConfig, previousConfig, force) {

    // no change, do nothing
    case (.none, .none, _):
      .none

    // no change, do nothing
    case (.some(let current), .some(let previous), false) where current.equals(previous):
      .none

    // no user anymore, just cancel
    case (.none, .some, _):
      .merge(
        .cancel(id: CancelId.screenshots),
        .exec { _ in await monitoring.stopLoggingKeystrokes() }
      )

    // current info changed (or we're forcing), reconfigure
    case (.some(let current), .some, _),
         (.some(let current), .none, _):
      .merge(
        .cancel(id: CancelId.screenshots),
        .exec { _ in
          guard current.keyloggingEnabled else {
            await monitoring.stopLoggingKeystrokes()
            return
          }
          await monitoring.keystrokeRecordingPermissionGranted()
            ? await monitoring.startLoggingKeystrokes()
            : await monitoring.stopLoggingKeystrokes()
        },
        .exec { send in
          guard current.screenshotsEnabled else {
            return
          }
          if await monitoring.screenRecordingPermissionGranted() {
            for await _ in bgQueue.timer(interval: .seconds(current.screenshotFrequency)) {
              await send(.monitoring(.timerTriggeredTakeScreenshot))
            }
          }
        }.cancellable(id: CancelId.screenshots, cancelInFlight: true)
      )
    }
  }
}

protocol MonitoringConfig: Sendable {
  var keyloggingEnabled: Bool { get }
  var screenshotsEnabled: Bool { get }
  var screenshotSize: Int { get }
  var screenshotFrequency: Int { get }
}

extension MonitoringConfig {
  func equals(_ other: MonitoringConfig) -> Bool {
    keyloggingEnabled == other.keyloggingEnabled
      && screenshotsEnabled == other.screenshotsEnabled
      && screenshotSize == other.screenshotSize
      && screenshotFrequency == other.screenshotFrequency
  }
}

struct UserMonitoringConfig: MonitoringConfig, Equatable, Sendable {
  var keyloggingEnabled: Bool
  var screenshotsEnabled: Bool
  var screenshotSize: Int
  var screenshotFrequency: Int
}

extension UserData: MonitoringConfig {
  func monitoring(
    merging extra: FilterSuspensionDecision.ExtraMonitoring
  ) -> UserMonitoringConfig {
    UserMonitoringConfig(
      keyloggingEnabled: extra.addsKeylogging || keyloggingEnabled,
      screenshotsEnabled: extra.setsScreenshotFrequency || screenshotsEnabled,
      screenshotSize: screenshotSize,
      screenshotFrequency: extra.screenshotsFrequency ?? screenshotFrequency
    )
  }
}
