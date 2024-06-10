public enum SecurityEvent: Equatable, Codable, Sendable {
  public enum MacApp: String, Codable, Equatable, Sendable {
    case filterSuspendedRemotely
    case filterSuspensionGrantedByAdmin
    case filterSuspensionExpired
    case filterSuspensionEndedEarly
    case systemExtensionChanged
    case appQuit
    case appLaunched
    case newMacOsUserCreated
    case macosUserExempted
    case childDisconnected
    case appUpdateInitiated
    case appUpdateSucceeded
    case appUpdateFailedToReplaceSystemExtension
    case advancedSettingsOpened
  }

  // NB: not used yet
  public enum Dashboard: String, Codable, Equatable, Sendable {
    case login
    case loginFailed
    case logout
    case passwordResetRequested
    case passwordChanged
    case childDeleted
    case childAdded
    case monitoringDecreased
    case keyCreated
    case keychainCreated
    case keychainsChanged
    case notificationDeleted
  }

  case macApp(MacApp)
  case dashboard(Dashboard)
}
