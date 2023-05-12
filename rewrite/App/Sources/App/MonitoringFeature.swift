import ComposableArchitecture
import MacAppRoute
import Models

enum MonitoringFeature {
  enum Action: Equatable {
    case timerTriggeredTakeScreenshot
  }

  struct RootReducer: RootReducing {
    @Dependency(\.api) var api
    @Dependency(\.backgroundQueue) var bgQueue
    @Dependency(\.monitoring) var monitoring
  }
}

private enum CancelId {
  case screenshots
}

extension MonitoringFeature.RootReducer {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    case .loadedPersistentState(.some(let persistent)):
      return configureScreenshots(current: persistent.user, previous: nil)

    case .user(.refreshRules(.success(let output), _)):
      return configureScreenshots(current: output, previous: state.user)

    case .history(.userConnection(.connect(.success(let user)))):
      return configureScreenshots(current: user, previous: nil)

    case .adminAuthenticated(.adminWindow(.webview(.reconnectUserClicked))):
      return .cancel(id: CancelId.screenshots)

    case .monitoring(.timerTriggeredTakeScreenshot):
      let width = state.user?.screenshotSize ?? 800
      return .run { _ in
        if let image = try await self.monitoring.takeScreenshot(width) {
          _ = try await api.uploadScreenshot(image.data, image.width, image.height)
        }
      }

    case .application(.willTerminate):
      return .cancel(id: CancelId.screenshots)

    default:
      return .none
    }
  }

  func configureScreenshots(
    current currentUser: ScreenshotUser?,
    previous previousUser: ScreenshotUser?
  ) -> Effect<Action> {
    switch (currentUser, previousUser) {

    // no change, do nothing
    case (.none, .none):
      return .none

    // no change, do nothing
    case (.some(let current), .some(let previous)) where current.equals(previous):
      return .none

    // no user anymore, just cancel
    case (.none, .some):
      return .cancel(id: CancelId.screenshots)

    // current screenshot info changed, tear down and restart
    case (.some(let current), .some), (.some(let current), .none):
      guard current.screenshotsEnabled else {
        return .cancel(id: CancelId.screenshots)
      }
      return .merge(
        .cancel(id: CancelId.screenshots),
        .run { send in
          for await _ in bgQueue.timer(interval: .seconds(current.screenshotFrequency)) {
            await send(.monitoring(.timerTriggeredTakeScreenshot))
          }
        }.cancellable(id: CancelId.screenshots, cancelInFlight: true)
      )
    }
  }
}

protocol ScreenshotUser: Sendable {
  var screenshotsEnabled: Bool { get }
  var screenshotSize: Int { get }
  var screenshotFrequency: Int { get }
}

extension ScreenshotUser {
  func equals(_ other: ScreenshotUser) -> Bool {
    screenshotsEnabled == other.screenshotsEnabled
      && screenshotSize == other.screenshotSize
      && screenshotFrequency == other.screenshotFrequency
  }
}

extension User: ScreenshotUser {}

extension RefreshRules.Output: ScreenshotUser {
  var screenshotSize: Int { screenshotsResolution }
  var screenshotFrequency: Int { screenshotsFrequency }
}
