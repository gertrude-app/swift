import Dependencies
import DependenciesMacros
import Foundation
import GertieIOS

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
  func saveBlockRules(_ rules: [BlockRule]) {
    self.saveCodable(value: rules, forKey: .blockRulesStorageKey)
  }

  func loadBlockRules() -> [BlockRule]? {
    self.loadData(forKey: .blockRulesStorageKey).flatMap { data in
      try? JSONDecoder().decode([BlockRule].self, from: data)
    }
  }

  func saveFirstLaunchDate(_ date: Date) {
    self.saveDate(date, forKey: .launchDateStorageKey)
  }

  func loadFirstLaunchDate() -> Date? {
    self.loadDate(forKey: .launchDateStorageKey)
  }
}

extension String {
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
