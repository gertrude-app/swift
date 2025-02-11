import Combine
import Dependencies
// import DependenciesMacros
import Foundation

#if os(iOS)
  import UIKit
#endif

// @DependencyClient
public struct DeviceClient: Sendable {
  public var type: DeviceType
  public var iOSVersion: String
  public var vendorId: UUID?
  public var batteryLevel: @Sendable () async -> BatteryLevel
  public var clearCache: @Sendable () -> AnyPublisher<ClearCacheUpdate, Never>

  public init(
    type: DeviceType,
    iOSVersion: String,
    vendorId: UUID?,
    batteryLevel: @Sendable @escaping () async -> BatteryLevel,
    clearCache: @Sendable @escaping () -> AnyPublisher<ClearCacheUpdate, Never>
  ) {
    self.type = type
    self.iOSVersion = iOSVersion
    self.vendorId = vendorId
    self.batteryLevel = batteryLevel
    self.clearCache = clearCache
  }
}

public extension DeviceClient {
  enum BatteryLevel: Sendable, Equatable {
    case unknown
    /// 0.0 - 1.0
    case level(Float)
  }

  enum ClearCacheUpdate: Sendable, Equatable {
    case bytesCleared(Int)
    case completed
  }
}

extension DeviceClient: DependencyKey {
  #if os(iOS)
    public static let liveValue = DeviceClient(
      type: UIDevice.current.userInterfaceIdiom == .pad ? .iPad : .iPhone,
      iOSVersion: UIDevice.current.systemVersion,
      vendorId: UIDevice.current.identifierForVendor,
      batteryLevel: {
        // 👍 TODO: check i get a good value on a real device
        // and that i don't need to enable monitoring earlier
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        UIDevice.current.isBatteryMonitoringEnabled = false
        return switch level {
        case 0.0 ... 1.0: .level(level)
        default: .unknown
        }
      }
    )
  #else
    public static let liveValue = DeviceClient(
      type: .iPhone,
      iOSVersion: "18.0.1",
      vendorId: nil,
      batteryLevel: { .level(0.9) },
      clearCache: { AnyPublisher(Empty()) }
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
