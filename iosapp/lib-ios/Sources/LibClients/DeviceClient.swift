import Dependencies
import DependenciesMacros
import Foundation

#if os(iOS)
  import UIKit
#endif

@DependencyClient
public struct DeviceClient: Sendable {
  public var type: DeviceType
  public var iOSVersion: String
  public var vendorId: UUID?

  public init(type: DeviceType, iOSVersion: String, vendorId: UUID?) {
    self.type = type
    self.iOSVersion = iOSVersion
    self.vendorId = vendorId
  }
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

public enum DeviceType: String, Sendable {
  case iPhone
  case iPad
}

public extension DependencyValues {
  var device: DeviceClient {
    get { self[DeviceClient.self] }
    set { self[DeviceClient.self] = newValue }
  }
}

public extension Duration {
  static func minutes(_ value: Int) -> Duration {
    .seconds(Double(value) * 60.0)
  }
}
