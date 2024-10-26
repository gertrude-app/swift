import Dependencies
import DependenciesMacros
import Foundation
import GertieIOS

@DependencyClient
struct StorageClient: Sendable {
  var saveDate: @Sendable (Date, _ forKey: String) -> Void
  var loadDate: @Sendable (_ forKey: String) -> Date?
  var saveCodable: @Sendable (_ value: any Codable, _ forKey: String) -> Void
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
    }
  )
}

extension StorageClient {
  func saveBlockRules(_ rules: [BlockRule]) {
    self.saveCodable(value: rules, forKey: .blockRulesStorageKey)
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

extension DependencyValues {
  var storage: StorageClient {
    get { self[StorageClient.self] }
    set { self[StorageClient.self] = newValue }
  }
}
