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
    case appUpdateSucceeded
    case appUpdateFailedToReplaceSystemExtension
    case advancedSettingsOpened
    case systemClockOrTimeZoneChanged
    case blockedAppLaunchAttempted
  }

  public enum Dashboard: String, Codable, Equatable, Sendable {
    case login
    case loginFailed
    case passwordResetRequested
    case passwordChanged
    case childDeleted
    case childAdded
    case childComputerDeleted
    case monitoringDecreased
    case keyCreated
    case keychainCreated
    case keychainsChanged
    case notificationDeleted
  }

  case macApp(MacApp)
  case dashboard(Dashboard)
}

public extension SecurityEvent.Dashboard {
  var toWords: String {
    switch self {
    case .childAdded:
      return "New child added"
    case .childDeleted:
      return "Child deleted"
    case .childComputerDeleted:
      return "Child computer deleted"
    case .keyCreated:
      return "Key created"
    case .keychainCreated:
      return "Keychain created"
    case .keychainsChanged:
      return "Child keychains changed"
    case .login:
      return "Successful login"
    case .loginFailed:
      return "Failed login"
    case .monitoringDecreased:
      return "Child monitoring decreased"
    case .notificationDeleted:
      return "Admin notification deleted"
    case .passwordChanged:
      return "Password changed"
    case .passwordResetRequested:
      return "Password reset requested"
    }
  }

  var explanation: String {
    switch self {
    case .childAdded:
      return "This event occurs when an parent creates a new child from the Gertrude parents admin site. It should occur very rarely, usually during account setup or when starting protection for a child. Should be investigated if it happened without your knowledge."
    case .childDeleted:
      return "This event occurs when a parent deletes a child from the Gertrude parents admin site. It should occur very rarely, when a child is no longer being protected. Should be investigated if it happened without your knowledge."
    case .childComputerDeleted:
      return "This event occurs when a parent deletes a child's computer from the Gertrude parents admin site. It should occur very rarely, usually when a child is no longer using a computer, or no longer being protected. Should be investigated if it happened without your knowledge."
    case .keyCreated:
      return "This event occurs when a new key is created and added to a keychain by a parent, either manually or by accepting an unlock request."
    case .keychainCreated:
      return "This event occurs when a parent creates a new keychain."
    case .keychainsChanged:
      return "This event occurs when a parent changes which keychains are assigned to a child. Should be investigated if the change was not made by you."
    case .login:
      return "This event occurs whenever a parent successfully logs into the parents admin website. Should be investigated if you do not recognize the successful login as your own."
    case .loginFailed:
      return "This event occurs whenever a parent fails to log into the parents admin website, usually from an incorrect password. Should be investigated if you do not recognize the failed attempt as your own."
    case .monitoringDecreased:
      return "This event occurs when the monitoring level for a child is decreased by a parent. It should be investigated if the monitoring level is decreased without your knowledge."
    case .notificationDeleted:
      return "This event occurs when a parent deletes a notification from the parents admin site. It should be investigated if a notification was deleted without your knowledge."
    case .passwordChanged:
      return "This event occurs when a parent changes their password for the parents admin site. Should be investigated if you did not change your password."
    case .passwordResetRequested:
      return "This event occurs when a parent requests a password reset for the parents admin site. Should be investigated if you did not request a password reset."
    }
  }
}

public extension SecurityEvent.MacApp {
  var toWords: String {
    switch self {
    case .advancedSettingsOpened:
      return "Advanced settings opened"
    case .appLaunched:
      return "App launched"
    case .appQuit:
      return "App quit"
    case .appUpdateFailedToReplaceSystemExtension:
      return "App update failed to replace system extension"
    case .appUpdateSucceeded:
      return "App update succeeded"
    case .childDisconnected:
      return "Child disconnected"
    case .filterSuspendedRemotely:
      return "Filter suspended remotely"
    case .filterSuspensionEndedEarly:
      return "Filter suspension ended early"
    case .filterSuspensionExpired:
      return "Filter suspension expired"
    case .filterSuspensionGrantedByAdmin:
      return "Filter suspension granted by admin"
    case .macosUserExempted:
      return "macOS user exempted"
    case .newMacOsUserCreated:
      return "New macOS user created"
    case .systemClockOrTimeZoneChanged:
      return "System clock or time zone changed"
    case .systemExtensionChangeRequested:
      return "System extension change requested"
    case .systemExtensionStateChanged:
      return "System extension state changed"
    case .blockedAppLaunchAttempted:
      return "Blocked app launch attempted"
    }
  }

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
    case .systemClockOrTimeZoneChanged:
      return "This event occurs when the system clock or time zone is changed. If there is not a legitimate reason for the clock or time zone to have changed, it could represent an attempt to circumvent time-based restrictions in Gertrude and should be investigated."
    case .systemExtensionChangeRequested:
      return "This event occurs whenever some action or process within Gertrude happens that requests a change to the state of the system extension (filter). It should be investigated if the request is to stop or uninstall the extension without it immediately being restarted or replaced."
    case .systemExtensionStateChanged:
      return "This event occurs when the system extension (filter) state has changed. It should be investigated if the state remains uninstalled or stopped."
    case .blockedAppLaunchAttempted:
      return "This event occurs when a child tries to launch an app designated blocked by the parent. There is no security risk as Gertrude will not allow the app to open, but repeated events do represent an attempt by the child to launch forbidden apps."
    }
  }
}
