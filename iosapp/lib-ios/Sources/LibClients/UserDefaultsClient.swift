import Dependencies
import DependenciesMacros
import Foundation
import GertieIOS
import IOSRoute
import LibCore

@DependencyClient
public struct UserDefaultsClient: Sendable {
  public var saveDate: @Sendable (Date, _ forKey: String) -> Void
  public var loadDate: @Sendable (_ forKey: String) -> Date?
  public var saveCodable: @Sendable (_ value: any Codable & Sendable, _ forKey: String) -> Void
  public var loadData: @Sendable (_ forKey: String) -> Data?
  public var saveData: @Sendable (_ data: Data, _ forKey: String) -> Void
  public var removeObject: @Sendable (_ forKey: String) -> Void
}

extension UserDefaultsClient: DependencyKey {
  public static let liveValue = UserDefaultsClient(
    saveDate: { date, key in
      UserDefaults.gertrude.set(date, forKey: key)
    },
    loadDate: {
      key in UserDefaults.gertrude.object(forKey: key) as? Date
    },
    saveCodable: { value, key in
      if let data = try? JSONEncoder().encode(value) {
        UserDefaults.gertrude.set(data, forKey: key)
      }
    },
    loadData: { key in
      UserDefaults.gertrude.data(forKey: key)
    },
    saveData: { data, key in
      UserDefaults.gertrude.set(data, forKey: key)
    },
    removeObject: { key in
      UserDefaults.gertrude.removeObject(forKey: key)
    }
  )
}

public extension UserDefaultsClient {
  func saveConnection(data: ChildIOSDeviceData_b1) {
    self.saveCodable(value: data, forKey: .connectionStorageKey)
  }

  func loadConnection() -> ChildIOSDeviceData_b1? {
    self.loadData(forKey: .connectionStorageKey).flatMap { data in
      try? JSONDecoder().decode(ChildIOSDeviceData_b1.self, from: data)
    }
  }

  func saveProtectionMode(_ protectionMode: ProtectionMode) {
    self.saveCodable(value: protectionMode, forKey: .protectionModeStorageKey)
  }

  func loadProtectionMode() -> ProtectionMode? {
    self.loadData(forKey: .protectionModeStorageKey).flatMap { data in
      try? JSONDecoder().decode(ProtectionMode.self, from: data)
    }
  }

  func load<T: Decodable>(decoding: T.Type, forKey key: String) -> T? {
    self.loadData(forKey: key).flatMap { data in
      try? JSONDecoder().decode(T.self, from: data)
    }
  }

  func saveDisabledBlockGroups(_ groups: [BlockGroup]) {
    self.saveCodable(value: groups, forKey: .disabledBlockGroupsStorageKey)
  }

  func loadDisabledBlockGroups() -> [BlockGroup]? {
    self.loadData(forKey: .disabledBlockGroupsStorageKey).flatMap { data in
      try? JSONDecoder().decode([BlockGroup].self, from: data)
    }
  }

  func saveFirstLaunchDate(_ date: Date) {
    self.saveDate(date, forKey: .launchDateStorageKey)
  }

  func loadFirstLaunchDate() -> Date? {
    self.loadDate(forKey: .launchDateStorageKey)
  }
}

public extension String {
  static var launchDateStorageKey: String {
    "firstLaunchDate"
  }

  static var legacyStorageKey: String {
    "blockRules.v1"
  }
}

extension UserDefaultsClient: TestDependencyKey {
  public static let testValue = UserDefaultsClient()
}

public extension DependencyValues {
  var sharedUserDefaults: UserDefaultsClient {
    get { self[UserDefaultsClient.self] }
    set { self[UserDefaultsClient.self] = newValue }
  }
}
