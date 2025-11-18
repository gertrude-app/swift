import Combine
import Dependencies
import Foundation

#if os(iOS)
  import UIKit
#endif

public struct DeviceClient: Sendable {
  @MainActor public var type: @Sendable () async -> DeviceType
  @MainActor public var iOSVersion: @Sendable () async -> String
  @MainActor public var vendorId: @Sendable () async -> UUID?
  @MainActor public var data: @Sendable () async -> Data
  @MainActor public var batteryLevel: @Sendable () async -> BatteryLevel
  public var clearCache: @Sendable (Int?) -> AnyPublisher<ClearCacheUpdate, Never>
  public var deleteCacheFillDir: @Sendable () async -> Void
  public var availableDiskSpaceInBytes: @Sendable () -> Int?

  public init(
    type: @Sendable @escaping () async -> DeviceType,
    iOSVersion: @Sendable @escaping () async -> String,
    vendorId: @Sendable @escaping () async -> UUID?,
    data: @Sendable @escaping () async -> Data,
    batteryLevel: @Sendable @escaping () async -> BatteryLevel,
    clearCache: @Sendable @escaping (Int?) -> AnyPublisher<ClearCacheUpdate, Never>,
    deleteCacheFillDir: @Sendable @escaping () async -> Void,
    availableDiskSpaceInBytes: @Sendable @escaping () -> Int?,
  ) {
    self.type = type
    self.iOSVersion = iOSVersion
    self.vendorId = vendorId
    self.data = data
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
      case .unknown: false
      case .level(let level): level < 0.4
      }
    }
  }

  enum ClearCacheUpdate: Sendable, Equatable {
    case bytesCleared(Int)
    case finished
    case errorCouldNotCreateDir
  }

  struct Data: Sendable {
    public var type: DeviceType
    public var iOSVersion: String
    public var vendorId: UUID?

    public init(type: DeviceType, iOSVersion: String, vendorId: UUID?) {
      self.type = type
      self.iOSVersion = iOSVersion
      self.vendorId = vendorId
    }
  }
}

extension DeviceClient: DependencyKey {
  #if os(iOS)
    public static var liveValue: DeviceClient {
      DeviceClient(
        type: { await MainActor.run {
          UIDevice.current.userInterfaceIdiom == .pad ? .iPad : .iPhone
        }},
        iOSVersion: { await MainActor.run {
          UIDevice.current.systemVersion
        }},
        vendorId: {
          await getStableVendorId()
        },
        data: {
          let vendorId = await getStableVendorId()
          return await MainActor.run { .init(
            type: UIDevice.current.userInterfaceIdiom == .pad ? .iPad : .iPhone,
            iOSVersion: UIDevice.current.systemVersion,
            vendorId: vendorId,
          ) }
        },
        batteryLevel: { @MainActor in
          UIDevice.current.isBatteryMonitoringEnabled = true
          let level = UIDevice.current.batteryLevel
          UIDevice.current.isBatteryMonitoringEnabled = false
          return switch level {
          case 0.0 ... 1.0: .level(level)
          default: .unknown
          }
        },
        clearCache: doClearCache,
        deleteCacheFillDir: { try? FileManager.default.removeItem(at: .fillDir) },
        availableDiskSpaceInBytes: getAvailableDiskSpaceInBytes,
      )
    }
  #else
    public static let liveValue = DeviceClient(
      type: { .iPhone },
      iOSVersion: { "18.0.1" },
      vendorId: { .init() },
      data: { .init(type: .iPhone, iOSVersion: "18.0.1", vendorId: .init()) },
      batteryLevel: { .level(0.9) },
      clearCache: { _ in AnyPublisher(Empty()) },
      deleteCacheFillDir: {},
      availableDiskSpaceInBytes: { 1_000_000_000 },
    )
  #endif
}

#if DEBUG
  public extension DeviceClient {
    static let mock = DeviceClient(
      type: { .iPhone },
      iOSVersion: { "18.3.1" },
      vendorId: { UUID(42) },
      data: { .init(type: .iPhone, iOSVersion: "18.3.1", vendorId: UUID(42)) },
      batteryLevel: { .level(0.85) },
      clearCache: { _ in AnyPublisher(Empty()) },
      deleteCacheFillDir: {},
      availableDiskSpaceInBytes: { 500_000_000 },
    )
  }
#endif

@Sendable func getStableVendorId() async -> UUID? {
  @Dependency(\.keychain) var keychain
  if let stored = keychain.loadVendorId() {
    return stored
  }
  let current: UUID? = await MainActor.run {
    #if os(iOS)
      UIDevice.current.identifierForVendor
    #else
      UUID()
    #endif
  }
  if let current {
    keychain.save(vendorId: current)
  }
  return current
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
