import Combine
import Dependencies
import Foundation

#if os(iOS)
  import UIKit
#endif

public struct DeviceClient: Sendable {
  public var type: DeviceType
  public var iOSVersion: String
  public var vendorId: UUID?
  public var batteryLevel: @Sendable () async -> BatteryLevel
  public var clearCache: @Sendable (Int?) -> AnyPublisher<ClearCacheUpdate, Never>
  public var deleteCacheFillDir: @Sendable () async -> Void
  public var availableDiskSpaceInBytes: @Sendable () async -> Int?

  public init(
    type: DeviceType,
    iOSVersion: String,
    vendorId: UUID?,
    batteryLevel: @Sendable @escaping () async -> BatteryLevel,
    clearCache: @Sendable @escaping (Int?) -> AnyPublisher<ClearCacheUpdate, Never>,
    deleteCacheFillDir: @Sendable @escaping () async -> Void,
    availableDiskSpaceInBytes: @Sendable @escaping () async -> Int?
  ) {
    self.type = type
    self.iOSVersion = iOSVersion
    self.vendorId = vendorId
    self.batteryLevel = batteryLevel
    self.clearCache = clearCache
    self.deleteCacheFillDir = deleteCacheFillDir
    self.availableDiskSpaceInBytes = availableDiskSpaceInBytes
  }
}

public extension DeviceClient {
  enum BatteryLevel: Sendable, Equatable {
    case unknown
    /// 0.0 - 1.0
    case level(Float)

    public var isLow: Bool {
      switch self {
      case .unknown: return false
      case .level(let level): return level < 0.35
      }
    }
  }

  enum ClearCacheUpdate: Sendable, Equatable {
    case bytesCleared(Int)
    case finished
    case errorCouldNotCreateDir
  }
}

extension DeviceClient: DependencyKey {
  #if os(iOS)
    public static let liveValue = DeviceClient(
      type: UIDevice.current.userInterfaceIdiom == .pad ? .iPad : .iPhone,
      iOSVersion: UIDevice.current.systemVersion,
      vendorId: UIDevice.current.identifierForVendor,
      batteryLevel: {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = await UIDevice.current.batteryLevel
        UIDevice.current.isBatteryMonitoringEnabled = false
        return switch level {
        case 0.0 ... 1.0: .level(level)
        default: .unknown
        }
      },
      clearCache: doClearCache,
      deleteCacheFillDir: { try? FileManager.default.removeItem(at: .fillDir) },
      availableDiskSpaceInBytes: getAvailableDiskSpaceInBytes
    )
  #else
    public static let liveValue = DeviceClient(
      type: .iPhone,
      iOSVersion: "18.0.1",
      vendorId: nil,
      batteryLevel: { .level(0.9) },
      clearCache: { _ in AnyPublisher(Empty()) },
      deleteCacheFillDir: {},
      availableDiskSpaceInBytes: { 1_000_000_000 }
    )
  #endif
}

@Sendable func getAvailableDiskSpaceInBytes() -> Int? {
  let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
  if let vals = try? url?.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
     let space = vals.volumeAvailableCapacityForImportantUsage {
    return space > Int.max ? nil : Int(space)
  }
  return nil
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
