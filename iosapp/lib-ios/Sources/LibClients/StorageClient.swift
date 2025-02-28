import Dependencies
import DependenciesMacros
import Foundation
import GertieIOS
import LibCore

@DependencyClient
public struct StorageClient: Sendable {
  public var saveDate: @Sendable (Date, _ forKey: String) -> Void
  public var loadDate: @Sendable (_ forKey: String) -> Date?
  public var saveCodable: @Sendable (_ value: any Codable, _ forKey: String) -> Void
  public var loadData: @Sendable (_ forKey: String) -> Data?
}

extension StorageClient: DependencyKey {
  public static let liveValue = StorageClient(
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
    }
  )
}

public extension StorageClient {
  func saveProtectionMode(_ protectionMode: ProtectionMode) {
    self.saveCodable(value: protectionMode, forKey: .protectionModeStorageKey)
  }

  func loadProtectionMode() -> ProtectionMode? {
    self.loadData(forKey: .protectionModeStorageKey).flatMap { data in
      try? JSONDecoder().decode(ProtectionMode.self, from: data)
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
}

extension StorageClient: TestDependencyKey {
  public static let testValue = StorageClient()
}

public extension DependencyValues {
  var storage: StorageClient {
    get { self[StorageClient.self] }
    set { self[StorageClient.self] = newValue }
  }
}
