import AppKit
import Combine
import Foundation
import Shared
import SharedCore
import Tagged

extension AdminWindowState {
  struct ActionsState: Equatable {
    struct FilterSuspension: Equatable {
      enum SuspensionType: String, Equatable {
        case browsers // deprecated, remove
        case allApps = "all apps"
      }

      var type: SuspensionType = .allApps
      var duration: Minutes<Int> = 5
    }

    struct Screenshot: Equatable {
      enum State: Equatable {
        case configuring
        case beingTaken
        case failed
        case succeeded(URL)
      }

      var size = 1000
      var state: State = .configuring
    }

    enum DebugSessionLength: Equatable {
      case fiveMinutes
      case oneHour
      case oneDay
    }

    var filterSuspension = FilterSuspension()
    var quitting = false
    var screenshot = Screenshot()
    var debugSessionLength = DebugSessionLength.fiveMinutes
  }
}

extension AppAction {
  enum AdminActionsAction: Equatable {
    case viewScreenshotButtonClicked
    case stopFilterButtonClicked
    case resumeFilterButtonClicked
    case startFilterButtonClicked
    case quitButtonClicked
    case viewLogsButtonClicked
    case disconnectButtonClicked
    case checkForUpdatesButtonClicked
    case forceAppUpdateButtonClicked
    case startDebugSessionButtonClicked
    case stopDebugSessionButtonClicked
    case debugSessionLengthChanged(AdminWindowState.ActionsState.DebugSessionLength)
    case filterSuspensionDurationChanged(Minutes<Int>)
    case filterSuspensionTypeChanged(AdminWindowState.ActionsState.FilterSuspension.SuspensionType)
    case filterSuspensionStarted
    case screenshotSizeChanged(Int)
    case autoUpdateReleaseChannelChanged(ReleaseChannel)
    case screenshotRequested
    case screenshotFailed
    case screenshotSucceeded(URL)
    case screenshotReturnToConfiguring
  }
}

func adminActionsReducer(
  state: inout AdminWindowState.ActionsState,
  action: AppAction.AdminActionsAction,
  environment: Env
) -> AnyPublisher<AppAction, Never>? {
  switch action {
  case .stopFilterButtonClicked:
    return dispatch(.stopFilter)
  case .resumeFilterButtonClicked:
    return dispatch(.adminActionsResumeFilterClicked)
  case .startFilterButtonClicked:
    return dispatch(.startFilter)

  case .quitButtonClicked:
    state.quitting = true
    return environment.os.quitApp()
      .map { .noop }
      .eraseToAnyPublisher()

  case .viewLogsButtonClicked,
       .startDebugSessionButtonClicked,
       .stopDebugSessionButtonClicked,
       .autoUpdateReleaseChannelChanged:
    assertionFailure("\(action) should be handled in parent (top level) reducer")

  case .viewScreenshotButtonClicked:
    guard case .succeeded(let url) = state.screenshot.state else { return nil }
    return Publishers.Merge(
      environment.os.openWebUrl(url).map { .noop },
      Just(.adminActions(.screenshotReturnToConfiguring))
        .delay(for: 3.0, scheduler: DispatchQueue.main)
    )
    .eraseToAnyPublisher()

  case .disconnectButtonClicked:
    return dispatch(.deleteUserToken)

  case .forceAppUpdateButtonClicked:
    return dispatch(.emitAppEvent(.forceAppUpdate))

  case .checkForUpdatesButtonClicked:
    return dispatch(.emitAppEvent(.requestCheckForUpdates))

  case .filterSuspensionDurationChanged(let duration):
    state.filterSuspension.duration = duration

  case .filterSuspensionTypeChanged(let type):
    state.filterSuspension.type = type

  case .filterSuspensionStarted:
    let suspension = FilterSuspension(
      scope: state.filterSuspension.type == .allApps ? .unrestricted : .webBrowsers,
      duration: .init(rawValue: state.filterSuspension.duration.rawValue * 60)
    )
    return dispatch(
      .receivedFilterSuspension(suspension),
      .emitAppEvent(.suspendFilter(suspension))
    )

  case .screenshotSizeChanged(let size):
    state.screenshot.size = size

  case .screenshotRequested:
    state.screenshot.state = .beingTaken
    return environment.screenshot.take(state.screenshot.size)
      .map { .adminActions(.screenshotSucceeded($0)) }
      .catch { _ in Just(.adminActions(.screenshotFailed)) }
      .eraseToAnyPublisher()

  case .screenshotFailed:
    state.screenshot.state = .failed
    return Just(.adminActions(.screenshotReturnToConfiguring))
      .delay(for: 5.0, scheduler: DispatchQueue.main)
      .eraseToAnyPublisher()

  case .screenshotSucceeded(let url):
    state.screenshot.state = .succeeded(url)

  case .screenshotReturnToConfiguring:
    state.screenshot.state = .configuring

  case .debugSessionLengthChanged(let length):
    state.debugSessionLength = length
  }

  return nil
}

typealias Minutes<Element: BinaryInteger> = Tagged<(tagged: (), minutes: ()), Element>

extension AdminWindowState.ActionsState.DebugSessionLength {
  var expiration: Date {
    switch self {
    case .fiveMinutes:
      return Date().advanced(by: .minutes(5))
    case .oneHour:
      return Date().advanced(by: .hours(1))
    case .oneDay:
      return Date().advanced(by: .hours(24))
    }
  }
}
