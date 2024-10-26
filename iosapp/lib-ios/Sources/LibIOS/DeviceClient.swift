import Dependencies
import DependenciesMacros
import Foundation

#if os(iOS)
  import UIKit
#endif

@DependencyClient
struct DeviceClient: Sendable {
  var type: DeviceType
  var iOSVersion: String
  var vendorId: UUID?
}

extension DeviceClient: DependencyKey {
  #if os(iOS)
    public static let liveValue = DeviceClient(
      type: UIDevice.current.userInterfaceIdiom == .pad ? .iPad : .iPhone,
      iOSVersion: UIDevice.current.systemVersion,
      vendorId: UIDevice.current.identifierForVendor
    )
  #else
    public static let liveValue = DeviceClient(
      type: .iPhone,
      iOSVersion: "18.0.1",
      vendorId: nil
    )
  #endif
}

enum DeviceType: String {
  case iPhone
  case iPad
}

extension DependencyValues {
  var device: DeviceClient {
    get { self[DeviceClient.self] }
    set { self[DeviceClient.self] = newValue }
  }
}
