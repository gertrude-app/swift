import Foundation
import Shared

enum AppEvent: Equatable {
  case closeMenuBarPopover
  case adminWindowOpened
  case requestsWindowOpened
  case logsWindowOpened
  case startDebugLogging(expiration: Date)
  case stopDebugLogging
  case userTokenChanged
  case filterStatusChanged
  case startFilter
  case stopFilter
  case removeFilter
  case appWindowLoggingChanged
  case consoleLoggingChanged
  case honeycombLoggingChanged
  case keyloggingStateChanged
  case screenshotsStateChanged
  case requestSuspendFilterWindowOpened
  case receivedRefreshRulesData(data: ApiClient.RefreshRulesData, notify: Bool)
  case showNotification(title: String, body: String)
  case suspendFilter(FilterSuspension)
  case cancelFilterSuspension
  case appWillSleep
  case appDidWake
  case requestCheckForUpdates
  case requestLatestAppVersion
  case forceAppUpdate
  case forceAutoUpdateToVersion(String)
  case setAutoUpdateReleaseChannel(ReleaseChannel)
  case receivedNewAccountStatus(AdminAccountStatus)
  case allPluginsAdded
  case websocketEndpointChanged
}

protocol AppEventReceiver {
  func notify(event: AppEvent)
}
