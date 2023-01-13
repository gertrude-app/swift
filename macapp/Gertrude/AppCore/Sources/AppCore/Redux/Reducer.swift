import Combine
import Foundation
import LaunchAtLogin
import SharedCore

func appReducer(
  state: inout AppState,
  action: AppAction,
  environment: Env
) -> AnyPublisher<AppAction, Never>? {
  switch action {
  case .receivedNewAppLog,
       .requestsWindowReceiveNewDecisions,
       .updateConnectionCode,
       .receivedRefreshRulesData,
       .emitAppEvent(.receivedRefreshRulesData),
       .healthCheck(.setInt),
       .healthCheck(.setString),
       .healthCheck(.setBool):
    break
  default:
    log(.level(.debug, "reducer received action", .primary("\(action)")))
  }

  switch action {
  case .openSystemPrefs(let location):
    return environment.os.openSystemPrefs(location)
      .map { .noop }
      .eraseToAnyPublisher()

  case .adminActions(.viewLogsButtonClicked):
    state.logging.toAppWindow = true
    return emit(.logsWindowOpened, .appWindowLoggingChanged)

  case .adminActions(.autoUpdateReleaseChannelChanged(let channel)):
    state.autoUpdateReleaseChannel = channel

  case .setAccountStatus(let status):
    let oldStatus = state.accountStatus
    state.accountStatus = status
    if status != oldStatus {
      return emit(.receivedNewAccountStatus(status))
    }

  case .requestCurrentAccountStatus:
    return environment.api.getAccountStatus()
      .map { .setAccountStatus($0) }
      .catch { _ in Empty() }
      .eraseToAnyPublisher()

  case .disconnectInactiveAccount:
    LaunchAtLogin.isEnabled = false
    return Publishers.Merge3(
      Just(.deleteUserToken),
      Just(.emitAppEvent(.removeFilter)),
      environment.os.quitApp().map { .noop }
    ).eraseToAnyPublisher()

  case .setAdminViewSection(let section):
    switch section {
    case .healthCheck:
      state.adminWindow = .healthCheck(.init())
    case .actions:
      state.adminWindow = .actions(.init())
    case .exemptUsers:
      state.adminWindow = .exemptUsers(.init())
    }

  case .setKeylogging(let enabled):
    state.monitoring.keyloggingEnabled = enabled
    Current.deviceStorage.setBool(.keyloggingEnabled, enabled)
    return dispatch(.emitAppEvent(.keyloggingStateChanged))

  case .setScreenshots(let enabled, let size, let frequency):
    state.monitoring.screenshotsEnabled = enabled
    state.monitoring.screenshotSize = size
    state.monitoring.screenshotFrequency = frequency
    Current.deviceStorage.setBool(.screenshotsEnabled, enabled)
    Current.deviceStorage.setInt(.screenshotSize, size)
    Current.deviceStorage.setInt(.screenshotFrequency, frequency)
    return emit(.screenshotsStateChanged)

  case .toggleConsoleLogging(enabled: let enabled):
    state.logging.toConsole = enabled
    return emit(.consoleLoggingChanged)

  case .closeAppLogsWindow:
    state.logging.toAppWindow = false
    return emit(.appWindowLoggingChanged)

  case .receivedNewAppLog(let log):
    state.loggingWindow.logs.append(.init(id: UUID(), identified: log))
    // prevent memory leak, if logs window left open, prevent more than 2k
    if state.loggingWindow.logs.count > 2000 {
      state.loggingWindow.logs = state.loggingWindow.logs.suffix(1000)
    }

  case .clearAppLogsClicked:
    state.loggingWindow.logs = []

  case .receivedRefreshRulesData(let data, let notify):
    return dispatch(
      .emitAppEvent(.receivedRefreshRulesData(data: data, notify: notify))
    )

  case .refreshRuleEntitiesError(let error, let notify):
    if notify {
      let notification = AppEvent.showNotification(
        title: "Error Refreshing Rules",
        body: errorMsg(.refreshRulesFailed(error))
      )
      return dispatch(.emitAppEvent(notification))
    }

  case .appLaunchRefreshRuleEntities,
       .receivedWebsocketMessageUserUpdated,
       .backgroundScheduledRefreshRuleEntities,
       .userInitiatedRefreshRules:
    let notify = action == .userInitiatedRefreshRules
    if action == .userInitiatedRefreshRules {
      App.shared.notify(event: .closeMenuBarPopover)
    }
    return environment.api.refreshRules()
      .map { .receivedRefreshRulesData(data: $0, notify: notify) }
      .catch { Just(.refreshRuleEntitiesError(error: $0, notify: notify)) }
      .eraseToAnyPublisher()

  case .submitUnlockRequestsClicked:
    transitionFetchState(&state, \.requestsWindow.unlockRequestFetchState, .setFetching)
    return environment.api
      .createUnlockRequests(
        state.requestsWindow.selectedRequests,
        state.requestsWindow.unlockRequestText
      )
      .map { _ in .unlockRequestsSubmittedSuccessfully }
      .catch { Just(.unlockRequestsSubmissionErrored($0)) }
      .flatMap { action in
        Publishers.Merge(
          Just(action),
          Just(.transitionFetchStateVoid(\.requestsWindow.unlockRequestFetchState, .setWaiting))
            .delay(for: 10.0, scheduler: DispatchQueue.main)
        )
      }
      .eraseToAnyPublisher()

  case .unlockRequestsSubmittedSuccessfully:
    state.requestsWindow.selectedRequests = []
    state.requestsWindow.unlockRequestText = ""
    transitionFetchState(&state, \.requestsWindow.unlockRequestFetchState, .setSuccess(()))

  case .unlockRequestsSubmissionErrored(let error):
    transitionFetchState(
      &state,
      \.requestsWindow.unlockRequestFetchState,
      .setError(errorMsg(.unlockRequestFailed(error)))
    )

  case .transitionFetchStateVoid(let keyPath, let stateAction):
    state[keyPath: keyPath] = state[keyPath: keyPath].respond(to: stateAction)

  case .updateUnlockRequestText(let text):
    state.requestsWindow.unlockRequestText = text

  case .initialConnectToUserClicked:
    state.adminWindow = .connect(AdminWindowState.ConnectState())
    App.shared.notify(event: .adminWindowOpened)

  case .requestsWindowReceiveNewDecisions(let requests):
    state.requestsWindow.requests += requests
    // prevent memory leak, if logs window left open, prevent more than 1k
    if state.requestsWindow.requests.count > 1000 {
      state.requestsWindow.requests = Array(state.requestsWindow.requests[500...])
    }

  case .requestsWindowClearRequestsClicked:
    if state.requestsWindow.selectedRequests.count == 0 {
      state.requestsWindow.requests = []
    } else {
      state.requestsWindow.requests = state.requestsWindow.requests.filter { req in
        state.requestsWindow.selectedRequests.contains(req.id)
      }
    }

  case .setFilterStatus(let status):
    state.filterStatus = status
    return dispatch(.emitAppEvent(.filterStatusChanged))

  case .startFilter:
    App.shared.notify(event: .startFilter)

  case .stopFilter:
    App.shared.notify(event: .stopFilter)

  case .emitAppEvent(let event):
    App.shared.notify(event: event)

  case .adminActions(.startDebugSessionButtonClicked):
    let expiration = state.adminWindow.actionsState.debugSessionLength.expiration
    state.logging.debugExpiration = expiration
    return emit(.startDebugLogging(expiration: expiration))

  case .adminActions(.stopDebugSessionButtonClicked):
    state.logging.debugExpiration = nil
    return emit(.stopDebugLogging)

  case .updateConnectionCode(let code):
    if case .connect(let data) = state.adminWindow {
      data.code = code
    }

  case .adminActionsResumeFilterClicked, .menuDropdownEnableFilterClicked:
    if state.filterStatus != .installedAndRunning {
      return dispatch(.emitAppEvent(.startFilter))
    } else {
      state.filterSuspension = nil
      App.shared.notify(event: .closeMenuBarPopover)
      return dispatch(.emitAppEvent(.cancelFilterSuspension))
    }

  case .menuDropdownViewRequestsClicked:
    App.shared.notify(event: .closeMenuBarPopover)
    App.shared.notify(event: .requestsWindowOpened)

  case .menuDropdownAdministrateClicked:
    state.adminWindow = .default
    App.shared.notify(event: .closeMenuBarPopover)
    App.shared.notify(event: .adminWindowOpened)

  case .tryAgainClickedAfterConnectToUserFailed:
    state.adminWindow = .connect(AdminWindowState.ConnectState())

  case .moreOptionsClickedAfterConnectToUserSuccess:
    state.adminWindow = .default

  case .connectToUser:
    let connect = state.adminWindow.connectState
    connect.fetchState = .fetching
    let code = Int(connect.code) ?? -999_999
    return environment.api
      .connectToUser(code)
      .map { .connectToUserSuccess(userId: $0, userToken: $1, userName: $2, deviceId: $3) }
      .catch { Just(.connectToUserError($0)) }
      .eraseToAnyPublisher()

  case .connectToUserError(let error):
    var message = "Something went wrong, please try again."
    if error.tag == .connectionCodeNotFound {
      message = "Code not found, or expired. Try re-entering, or create a new code."
    }
    state.adminWindow.connectState.fetchState = .error(message)

  case .connectToUserSuccess(
    userId: let userId,
    userToken: let userToken,
    userName: let userName,
    deviceId: let deviceId
  ):
    Current.deviceStorage.setUUID(.gertrudeUserId, userId)
    Current.deviceStorage.setUUID(.gertrudeDeviceId, deviceId)
    state.adminWindow.connectState.fetchState = .success(userName)
    return dispatch(.setUserToken(userToken), .emitAppEvent(.userTokenChanged))

  case .setUserToken(let token):
    state.userToken = token
    Current.deviceStorage.setUUID(.userToken, token)
    return emit(.userTokenChanged)

  case .deleteUserToken:
    state.userToken = nil
    Current.deviceStorage.delete(.userToken)
    Current.deviceStorage.delete(.gertrudeUserId)
    state.adminWindow = .connect(AdminWindowState.ConnectState())
    return dispatch(.emitAppEvent(.userTokenChanged))

  case .requestsWindowSetFilterBlocksOnly(let blocksOnly):
    state.requestsWindow.filter.showBlockedRequestsOnly = blocksOnly

  case .requestsWindowSetFilterTcpOnly(let tcpOnly):
    state.requestsWindow.filter.showTcpRequestsOnly = tcpOnly

  case .requestsWindowSetFiltering(let byText):
    state.requestsWindow.filter.byText = byText

  case .requestsWindowSetFilterText(let text):
    state.requestsWindow.filter.text = text

  case .setColorScheme(let colorScheme):
    state.colorScheme = colorScheme

  case .requestsWindowToggleSelected(let id):
    if state.requestsWindow.selectedRequests.contains(id) {
      state.requestsWindow.selectedRequests.remove(id)
    } else {
      state.requestsWindow.selectedRequests.insert(id)
    }

  case .menuDropdownDisableFilterTemporarilyClicked:
    App.shared.notify(event: .closeMenuBarPopover)
    return dispatch(.emitAppEvent(.requestSuspendFilterWindowOpened))

  case .updateFilterSuspensionDuration(let duration):
    state.requestFilterSuspensionWindow.duration = duration

  case .updateFilterSuspensionCustomDuration(let customDuration):
    state.requestFilterSuspensionWindow.customDuration = customDuration

  case .updateFilterSuspensionComment(let comment):
    state.requestFilterSuspensionWindow.comment = comment

  case .filterSuspensionExpired:
    state.filterSuspension = nil

  case .requestFilterSuspensionWindowClosed:
    state.requestFilterSuspensionWindow = .init()

  case .submitRequestFilterSuspensionClicked:
    transitionFetchState(&state, \.requestFilterSuspensionWindow.fetchState, .setFetching)
    let seconds = state.requestFilterSuspensionWindow.durationSeconds
    let comment = state.requestFilterSuspensionWindow.comment
    return environment.api.createSuspendFilterRequest(seconds, comment.isEmpty ? nil : comment)
      .map { _ in .filterSuspensionRequestSubmittedSuccessfully }
      .catch { Just(.filterSuspensionRequestSubmissionErrored($0)) }
      .eraseToAnyPublisher()

  case .filterSuspensionRequestSubmittedSuccessfully:
    transitionFetchState(&state, \.requestFilterSuspensionWindow.fetchState, .setSuccess(()))

  case .filterSuspensionRequestSubmissionErrored(let error):
    transitionFetchState(
      &state,
      \.requestFilterSuspensionWindow.fetchState,
      .setError(errorMsg(.filterSuspensionRequestFailed(error)))
    )

  case .receivedFilterSuspension(let suspension):
    state.filterSuspension = suspension

  case .noop:
    break

  case .healthCheck(let healthCheckAction):
    return healthCheckReducer(
      state: &state.adminWindow.healthCheckState,
      action: healthCheckAction,
      environment: environment
    )

  case .exemptUser(let exemptUserAction):
    return exemptUserReducer(
      state: &state.adminWindow.exemptUsersState,
      action: exemptUserAction,
      environment: environment
    ).flatMap { $0.map { .exemptUser($0) }.eraseToAnyPublisher() }

  case .adminActions(let adminActionsAction):
    return adminActionsReducer(
      state: &state.adminWindow.actionsState,
      action: adminActionsAction,
      environment: environment
    )
  }

  return nil
}

typealias AppStore = Store<AppState, AppAction, Env>

func emit(_ event: AppEvent) -> AnyPublisher<AppAction, Never> {
  Just(AppAction.emitAppEvent(event)).eraseToAnyPublisher()
}

func dispatch(_ action: AppAction) -> AnyPublisher<AppAction, Never> {
  Just(action).eraseToAnyPublisher()
}

func dispatch(_ action1: AppAction, _ action2: AppAction) -> AnyPublisher<AppAction, Never> {
  Publishers.Merge(Just(action1), Just(action2)).eraseToAnyPublisher()
}

func emit(_ event1: AppEvent, _ event2: AppEvent) -> AnyPublisher<AppAction, Never> {
  Publishers.Merge(
    Just(AppAction.emitAppEvent(event1)),
    Just(AppAction.emitAppEvent(event2))
  ).eraseToAnyPublisher()
}

func nilReducer(
  state: inout AppState,
  action: AppAction,
  environment: Env
) -> AnyPublisher<AppAction, Never>? {
  nil
}

private func transitionFetchState<T>(
  _ state: inout AppState,
  _ keyPath: WritableKeyPath<AppState, FetchState<T>>,
  _ fetchAction: FetchState<T>.Action
) {
  state[keyPath: keyPath] = state[keyPath: keyPath].respond(to: fetchAction)
}
