import ComposableArchitecture
import Gertie
import MacAppRoute

enum MonitoringFeature {
  enum Action: Equatable {
    case timerTriggeredTakeScreenshot
  }

  struct RootReducer: RootReducing {
    @Dependency(\.api) var api
    @Dependency(\.backgroundQueue) var bgQueue
    @Dependency(\.monitoring) var monitoring
    @Dependency(\.network) var network
  }
}

private enum CancelId {
  case screenshots
}

extension MonitoringFeature.RootReducer {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    case .loadedPersistentState(.some(let persistent)):
      return configureMonitoring(current: persistent.user, previous: nil)

    case .user(.updated(let previous)):
      return configureMonitoring(current: state.user.data, previous: previous)

    case .history(.userConnection(.connect(.success(let user)))):
      return configureMonitoring(current: user, previous: nil)

    case .monitoring(.timerTriggeredTakeScreenshot):
      let width = state.user.data?.screenshotSize ?? 800
      return .exec { _ in
        try await monitoring.takeScreenshot(width)
        guard network.isConnected() else { return }
        for sc in await monitoring.takePendingScreenshots() {
          _ = try await api.uploadScreenshot(sc.data, sc.width, sc.height, sc.createdAt)
        }
      }

    // for simplicity's sake, ALWAYS try to upload any pending keystrokes
    // so we don't have to worry about edge cases when we stop/restart.
    // if we're not monitoring keystrokes, keystrokes will be nil
    case .heartbeat(.everyFiveMinutes),
         .adminAuthed(.adminWindow(.webview(.confirmQuitAppClicked))):
      return .exec { _ in
        guard network.isConnected() else { return }
        if let keystrokes = await monitoring.takePendingKeystrokes() {
          _ = try await api.createKeystrokeLines(keystrokes)
        }
      }

    case .application(.willTerminate):
      return .cancel(id: CancelId.screenshots)

    case .adminAuthed(.adminWindow(.webview(.reconnectUserClicked))):
      return .cancel(id: CancelId.screenshots)

    // try to catch the moment when they've fixed monitoring permissions issues
    case .adminWindow(.webview(.healthCheck(.recheckClicked))):
      return configureMonitoring(current: state.user.data, previous: nil, force: true)

    default:
      return .none
    }
  }

  func configureMonitoring(
    current currentUser: MonitoredUser?,
    previous previousUser: MonitoredUser?,
    force: Bool = false
  ) -> Effect<Action> {
    switch (currentUser, previousUser, force) {

    // no change, do nothing
    case (.none, .none, _):
      return .none

    // no change, do nothing
    case (.some(let current), .some(let previous), false) where current.equals(previous):
      return .none

    // no user anymore, just cancel
    case (.none, .some, _):
      return .merge(
        .cancel(id: CancelId.screenshots),
        .exec { _ in await monitoring.stopLoggingKeystrokes() }
      )

    // current info changed (or we're forcing), reconfigure
    case (.some(let current), .some, _), (.some(let current), .none, _):
      return .merge(
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

protocol MonitoredUser: Sendable {
  var keyloggingEnabled: Bool { get }
  var screenshotsEnabled: Bool { get }
  var screenshotSize: Int { get }
  var screenshotFrequency: Int { get }
}

extension MonitoredUser {
  func equals(_ other: MonitoredUser) -> Bool {
    keyloggingEnabled == other.keyloggingEnabled
      && screenshotsEnabled == other.screenshotsEnabled
      && screenshotSize == other.screenshotSize
      && screenshotFrequency == other.screenshotFrequency
  }
}

extension UserData: MonitoredUser {}
