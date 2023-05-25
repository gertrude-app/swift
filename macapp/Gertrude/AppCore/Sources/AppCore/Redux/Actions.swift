import Foundation
import Gertie
import SharedCore
import SwiftUI

enum AppAction: Equatable {
  case setAdminViewSection(AdminScreenSection)
  case healthCheck(HealthCheckAction)
  case exemptUser(ExemptUserAction)
  case adminActions(AdminActionsAction)
  case adminActionsResumeFilterClicked

  case emitAppEvent(AppEvent)
  case setAccountStatus(AdminAccountStatus)
  case requestCurrentAccountStatus
  case disconnectInactiveAccount
  case setUserToken(UUID)

  case openSystemPrefs(SystemPrefsLocation)
  case setColorScheme(ColorScheme)

  case initialConnectToUserClicked
  case menuDropdownViewRequestsClicked
  case userInitiatedRefreshRules
  case menuDropdownAdministrateClicked
  case menuDropdownDisableFilterTemporarilyClicked
  case menuDropdownEnableFilterClicked

  case appLaunchRefreshRuleEntities
  case receivedRefreshRulesData(data: ApiClient.RefreshRulesData, notify: Bool)
  case receivedFilterSuspension(FilterSuspension)
  case refreshRuleEntitiesError(error: ApiClient.Error, notify: Bool)
  case receivedWebsocketMessageUserUpdated
  case backgroundScheduledRefreshRuleEntities
  case filterSuspensionExpired

  case transitionFetchStateVoid(
    WritableKeyPath<AppState, FetchState<Void>>,
    FetchState<Void>.Action
  )

  // windows
  case tryAgainClickedAfterConnectToUserFailed
  case moreOptionsClickedAfterConnectToUserSuccess

  // filter
  case setFilterStatus(FilterStatus)
  case startFilter
  case stopFilter

  // admin window -> connect screen
  case updateConnectionCode(String)
  case connectToUser
  case connectToUserError(ApiClient.Error)
  case connectToUserSuccess(userId: UUID, userToken: UUID, userName: String, deviceId: UUID)

  // admin window -> main screen
  case deleteUserToken

  // requests window
  case requestsWindowSetFilterBlocksOnly(Bool)
  case requestsWindowSetFilterTcpOnly(Bool)
  case requestsWindowSetFiltering(Bool)
  case requestsWindowSetFilterText(String)
  case requestsWindowToggleSelected(UUID)
  case requestsWindowReceiveNewDecisions([FilterDecision])
  case requestsWindowClearRequestsClicked
  case updateUnlockRequestText(String)
  case submitUnlockRequestsClicked
  case unlockRequestsSubmittedSuccessfully
  case unlockRequestsSubmissionErrored(ApiClient.Error)

  // request filter suspension window
  case updateFilterSuspensionDuration(RequestFilterSuspensionWindowState.Duration)
  case updateFilterSuspensionCustomDuration(String)
  case updateFilterSuspensionComment(String)
  case submitRequestFilterSuspensionClicked
  case filterSuspensionRequestSubmittedSuccessfully
  case filterSuspensionRequestSubmissionErrored(ApiClient.Error)
  case requestFilterSuspensionWindowClosed

  // logs
  case receivedNewAppLog(Log.Message)
  case clearAppLogsClicked
  case closeAppLogsWindow
  case toggleConsoleLogging(enabled: Bool)

  // monitoring
  case setKeylogging(enabled: Bool)
  case setScreenshots(enabled: Bool, size: Int, frequency: Int)

  case noop
}

typealias Dispatch = () -> Void
