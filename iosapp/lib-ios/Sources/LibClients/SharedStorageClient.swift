import Dependencies
import DependenciesMacros
import Foundation
import GertieIOS
import IOSRoute
import LibCore
import os.log

@DependencyClient
public struct SharedStorageClient: Sendable {
  public var loadAccountConnection: @Sendable () -> ChildIOSDeviceData?
  public var saveAccountConnection: @Sendable (ChildIOSDeviceData) -> Void

  public var loadProtectionMode: @Sendable () -> ProtectionMode?
  public var saveProtectionMode: @Sendable (ProtectionMode) -> Void

  public var loadDisabledBlockGroups: @Sendable () -> [BlockGroup]?
  public var saveDisabledBlockGroups: @Sendable ([BlockGroup]) -> Void

  public var loadFirstLaunchDate: @Sendable () -> Date?
  public var saveFirstLaunchDate: @Sendable (Date) -> Void

  public var loadDebugLogs: @Sendable () -> [String]?
  public var saveDebugLogs: @Sendable ([String]) -> Void

  public var migrateLegacyData: @Sendable () async -> Bool = { false }
}

@DependencyClient
public struct SharedStorageReaderClient: Sendable {
  public var loadAccountConnection: @Sendable () -> ChildIOSDeviceData?
  public var loadProtectionMode: @Sendable () -> ProtectionMode?
  public var loadDisabledBlockGroups: @Sendable () -> [BlockGroup]?
  public var loadFirstLaunchDate: @Sendable () -> Date?
  public var loadDebugLogs: @Sendable () -> [String]?
}

private enum Key: String {
  case accountConnection = "v1.5.0--account-connection"
  case debugLogs = "v1.5.0--debug-logs"
  case legacyProtectionMode = "ProtectionMode.v1.3.0"
  case protectionMode = "v1.5.0--protection-mode"
  case disabledBlockGroups = "disabledBlockGroups.v1.3.0"
  case legacyV1StorageKey = "blockRules.v1"
  case firstLaunchDate
}

extension SharedStorageClient: DependencyKey {
  public static var liveValue: SharedStorageClient {
    let reader = SharedStorageReaderClient.liveValue
    return .init(
      loadAccountConnection: reader.loadAccountConnection,
      saveAccountConnection: { saveCodable($0, forKey: .accountConnection) },
      loadProtectionMode: reader.loadProtectionMode,
      saveProtectionMode: { saveCodable($0, forKey: .protectionMode) },
      loadDisabledBlockGroups: reader.loadDisabledBlockGroups,
      saveDisabledBlockGroups: { saveCodable($0, forKey: .disabledBlockGroups) },
      loadFirstLaunchDate: reader.loadFirstLaunchDate,
      saveFirstLaunchDate: { saveDate($0, forKey: .firstLaunchDate) },
      loadDebugLogs: reader.loadDebugLogs,
      saveDebugLogs: { saveCodable($0, forKey: .debugLogs) },
      migrateLegacyData: { await migrateLegacyStorage() },
    )
  }
}

public extension SharedStorageClient {
  func saveDebugLog(_ log: String) {
    var logs = self.loadDebugLogs() ?? []
    logs.append(log)
    self.saveDebugLogs(logs)
  }
}

extension SharedStorageReaderClient: DependencyKey {
  public static let liveValue = SharedStorageReaderClient(
    loadAccountConnection: { loadCodable(forKey: .accountConnection) },
    loadProtectionMode: { loadCodable(forKey: .protectionMode) },
    loadDisabledBlockGroups: { loadCodable(forKey: .disabledBlockGroups) },
    loadFirstLaunchDate: { loadDate(forKey: .firstLaunchDate) },
    loadDebugLogs: { loadCodable(forKey: .debugLogs) },
  )
}

func migrateLegacyStorage() async -> Bool {
  if UserDefaults.gertrude.data(forKey: Key.protectionMode.rawValue) != nil {
    return false // fast path, they have current data, we're done
  }
  @Dependency(\.api) var api

  // migrate 1.3.x data to 1.5.x
  if let v13x: ProtectionMode.Legacy = loadCodable(forKey: .legacyProtectionMode) {
    let current = v13x.toCurrent()
    saveCodable(current, forKey: .protectionMode)
    var disabledGroups: [BlockGroup] = loadCodable(forKey: .disabledBlockGroups) ?? []
    if !disabledGroups.contains(.spotifyImages) {
      disabledGroups.append(.spotifyImages)
    }
    saveCodable(disabledGroups, forKey: .disabledBlockGroups)
    await api.logEvent(id: "edd6e55f", detail: "migrated v1.3.x -> 1.5.x")
    return true
  }

  // 1.4.x testflight users had new data in old location
  if let v14x: ProtectionMode = loadCodable(forKey: .legacyProtectionMode) {
    saveCodable(v14x, forKey: .protectionMode)
    await api.logEvent(id: "90442103", detail: "migrated v1.4.x (TestFlight) -> 1.5.x")
    return true
  }

  if UserDefaults.gertrude.data(forKey: Key.legacyProtectionMode.rawValue) != nil {
    await api.logEvent(id: "fdab6cff", detail: "unexpected migration error")
    return false
  }

  if UserDefaults.gertrude.data(forKey: Key.legacyV1StorageKey.rawValue) == nil {
    // no data, nothing to migrate, probably initial launch
    return false
  }

  // migrate < 1.3.x very old data, from 1.0/1 -> 1.5
  @Dependency(\.device) var device
  saveCodable([BlockGroup.spotifyImages], forKey: .disabledBlockGroups)
  if let defaultRules = try? await api.fetchDefaultBlockRules(device.vendorId()) {
    await api.logEvent(id: "c732e0ab", detail: "migrated v1.1.x -> 1.5.x")
    saveCodable(ProtectionMode.normal(defaultRules), forKey: .protectionMode)
  } else {
    saveCodable(
      // setting to .onboarding will produce faster api re-check to recover from this state
      ProtectionMode.onboarding(BlockRule.Legacy.defaults.map(\.current)),
      forKey: .protectionMode,
    )
    await api.logEvent(id: "8d4a445b", detail: "error migrating v1.1.x -> 1.5.x")
  }
  return true
}

private func saveCodable(_ value: some Codable, forKey key: Key) {
  if let data = try? JSONEncoder().encode(value) {
    UserDefaults.gertrude.set(data, forKey: key.rawValue)
  }
}

private func loadCodable<T: Codable>(forKey key: Key) -> T? {
  guard let data = UserDefaults.gertrude.data(forKey: key.rawValue) else { return nil }
  return try? JSONDecoder().decode(T.self, from: data)
}

private func saveDate(_ date: Date, forKey key: Key) {
  UserDefaults.gertrude.set(date, forKey: key.rawValue)
}

private func loadDate(forKey key: Key) -> Date? {
  UserDefaults.gertrude.object(forKey: key.rawValue) as? Date
}

public extension DependencyValues {
  var sharedStorage: SharedStorageClient {
    get { self[SharedStorageClient.self] }
    set { self[SharedStorageClient.self] = newValue }
  }
}

public extension DependencyValues {
  var sharedStorageReader: SharedStorageReaderClient {
    get { self[SharedStorageReaderClient.self] }
    set { self[SharedStorageReaderClient.self] = newValue }
  }
}

extension SharedStorageClient {
  func osLogBufferedDebugLogs(prefix: String) {
    let allLogs = self.loadDebugLogs() ?? []
    for (i, logs) in allLogs.chunked(into: 6).enumerated() {
      os_log(
        "[G•] %{public}s buffered logs %d:\n%{public}s",
        i + 1,
        prefix,
        logs.joined(separator: "\n"),
      )
    }
  }
}

extension ProtectionMode {
  enum Legacy: Codable {
    case onboarding([BlockRule.Legacy])
    case normal([BlockRule.Legacy])
    case emergencyLockdown

    func toCurrent() -> ProtectionMode {
      switch self {
      case .onboarding(let rules):
        .onboarding(rules.map(\.current))
      case .normal(let rules):
        .normal(rules.map(\.current))
      case .emergencyLockdown:
        .emergencyLockdown
      }
    }
  }
}
