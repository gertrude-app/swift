import Dependencies
import DependenciesMacros
import Foundation
import GertieIOS
import IOSRoute
import LibCore

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
}

@DependencyClient
public struct SharedStorageReaderClient: Sendable {
  public var loadAccountConnection: @Sendable () -> ChildIOSDeviceData?
  public var loadProtectionMode: @Sendable () -> ProtectionMode?
  public var loadDisabledBlockGroups: @Sendable () -> [BlockGroup]?
  public var loadFirstLaunchDate: @Sendable () -> Date?
}

private enum Key: String {
  case accountConnection = "v1.5.0--account-connection"
  case protectionMode = "ProtectionMode.v1.3.0"
  case disabledBlockGroups = "disabledBlockGroups.v1.3.0"
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
      saveFirstLaunchDate: { saveDate($0, forKey: .firstLaunchDate) }
    )
  }
}

extension SharedStorageReaderClient: DependencyKey {
  public static let liveValue = SharedStorageReaderClient(
    loadAccountConnection: { loadCodable(forKey: .accountConnection) },
    loadProtectionMode: { loadCodable(forKey: .protectionMode) },
    loadDisabledBlockGroups: { loadCodable(forKey: .disabledBlockGroups) },
    loadFirstLaunchDate: { loadDate(forKey: .firstLaunchDate) }
  )
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
