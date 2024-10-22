import FamilyControls
import IOSRoute
import NetworkExtension
import os.log

#if os(iOS)
  import UIKit
#endif

struct Device {
  var type: String
  var iOSVersion: String
  var vendorId: UUID?
}

extension Device {
  static var current: Device {
    #if os(iOS)
      Device(
        type: UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone",
        iOSVersion: UIDevice.current.systemVersion,
        vendorId: UIDevice.current.identifierForVendor
      )
    #else
      Device(type: "iPhone", iOSVersion: "18.0.1", vendorId: nil)
    #endif
  }
}

// @see https://developer.apple.com/documentation/familycontrols/familycontrolserror
public enum AuthFailureReason: Error, Equatable {
  // The device isn't signed into a valid iCloud account (also? .individual?)
  case invalidAccountType
  /// Another authorized app already provides parental controls
  case authorizationConflict
  case unexpected(Unexpected)
  case other(String)
  /// Device must be connected to the network in order to enroll with parental controls
  case networkError
  /// The device must have a passcode set in order for an individual to enroll with parental controls
  case passcodeRequired
  /// The parent or guardian cancelled a request for authorization
  case authorizationCanceled
  /// A restriction prevents your app from using Family Controls on this device
  /// likely an MDM supervised device, see https://developer.apple.com/forums/thread/746716
  case restricted

  public enum Unexpected: Equatable {
    /// The method's arguments are invalid
    case invalidArgument
    /// The system failed to set up the Family Control famework
    case unavailable
  }
}

public enum FilterInstallError: Error, Equatable {
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

extension String {
  static var gertrudeApi: String {
    #if DEBUG
      // just run-api-ip
      return "http://192.168.10.227:8080/pairql/ios-app"
    #else
      return "https://api.gertrude.app/pairql/ios-app"
    #endif
  }

  static var launchDateStorageKey: String {
    "firstLaunchDate"
  }
}
