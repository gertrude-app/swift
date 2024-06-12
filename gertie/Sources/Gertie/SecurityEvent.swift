public enum SecurityEvent: Equatable, Codable, Sendable {
  public enum MacApp: String, Codable, Equatable, Sendable {
    case filterSuspendedRemotely
    case filterSuspensionGrantedByAdmin
    case filterSuspensionExpired
    case filterSuspensionEndedEarly
    case systemExtensionChangeRequested
    case systemExtensionStateChanged
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

public extension SecurityEvent.MacApp {
  var explanation: String {
    switch self {
    case .advancedSettingsOpened:
      return "This event occurs when an admin-privileged user opens a hidden, advanced settings area in the Administrate screen. This is an unexpected event that usually only occurs when a parent is instructed by Gertrude support to access this area. It should be investigated."
    case .appLaunched:
      return "This event occurs when the Gertrude app is launched. Only investigate it if seems to be occuring more than expected."
    case .appQuit:
      return "This event occurs when an admin-privileged user quits the Gertrude app. For a protected child, this should not occur and should be investigated."
    case .appUpdateFailedToReplaceSystemExtension:
      return "This is a rare event that occurs when a Gertrude update fails. It does not represent any attempt by the protected child to bypass Gertrude, but should be investigated to make sure the filter is functioning correctly."
    case .appUpdateInitiated:
      return "This event occurs when an upgrade to the Gertrude app is initiated. It is normal, but should be infrequent."
    case .appUpdateSucceeded:
      return "This event occurs when an upgrade to the Gertrude app finishes successfully. It is normal, but should be infrequent."
    case .childDisconnected:
      return "This event occurs when the Gertrude macOS app is disconnected from protecting a child. It should not occur unless the app is being uninstalled, or a different child is connected soon after."
    case .filterSuspendedRemotely:
      return "This event occurs when a parent account accepts a request to suspend the filter. As long as the parent accepted the request, this event is normal."
    case .filterSuspensionEndedEarly:
      return "This event occurs when the child ends a filter suspension early. It does not represent a safety risk."
    case .filterSuspensionExpired:
      return "This event occurs when a filter suspension ends after the scheduled time. It does not represent a safety risk."
    case .filterSuspensionGrantedByAdmin:
      return "This event occurs when a filter suspension is granted from the computer by a admin-privileged user. If a parent did not authenticate, this represents the child suspending the filter themselves."
    case .macosUserExempted:
      return "This event occurs when a admin-privileged user exempts another macOS user from being filtered by Gertrude. Unless the parent is responsible for this action, it should be investigated."
    case .newMacOsUserCreated:
      return "This event occurs when a new macOS user is created on the computer. It could represent an attempt to bypass Gertrude, but could also be normal."
    case .systemExtensionChangeRequested:
      return "This event occurs whenever some action or process within Gertrude happens that requests a change to the state of the system extension (filter). It should be investigated if the request is to stop or uninstall the extension without it immediately being restarted or replaced."
    case .systemExtensionStateChanged:
      return "This event occurs when the system extension (filter) state has changed. It should be investigated if the state remains uninstalled or stopped."
    }
  }
}
