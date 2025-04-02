// @see https://developer.apple.com/documentation/familycontrols/familycontrolserror
public enum AuthFailureReason: Error, Equatable, Sendable {
  /// The device isn't signed into a valid iCloud account (according to docs)
  /// but i've verified this also is what you get with 18+ iCloud account
  case invalidAccountType
  /// Another authorized app already provides parental controls
  case authorizationConflict
  case unexpected(Unexpected)
  case other(String)
  /// Device must be connected to the network in order to enroll with parental controls
  case networkError
  /// The device must have a passcode set in order for an individual to enroll with parental
  /// controls
  case passcodeRequired
  /// The parent or guardian cancelled a request for authorization
  case authorizationCanceled
  /// A restriction prevents your app from using Family Controls on this device
  /// likely an MDM supervised device, see https://developer.apple.com/forums/thread/746716
  case restricted

  public enum Unexpected: Equatable, Sendable {
    /// The method's arguments are invalid
    case invalidArgument
    /// The system failed to set up the Family Control famework
    case unavailable
  }
}

public enum FilterInstallError: Error, Equatable, Sendable {
  case configurationInvalid
  case configurationDisabled
  /// another process modified the filter configuration
  /// since the last time the app loaded the configuration
  case configurationStale
  /// removing the configuration isn't allowed
  case configurationCannotBeRemoved
  case configurationPermissionDenied
  case configurationInternalError
  case unexpected(String)
}
