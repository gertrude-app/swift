import os.log
import XCore

public protocol Migrator {
  associatedtype State: PersistentState
  var userDefaults: UserDefaultsClient { get }
  var context: String { get }
  func migrateLastVersion() async -> State?
}

public extension Migrator {
  func migrate() async -> State? {
    let current = try? self.userDefaults.getString(State.storageKey).flatMap { json in
      try JSON.decode(json, as: State.self)
    }
    if let current {
      self.log("found current state, no migration necessary")
      return current
    } else if let migrated = await self.migrateLastVersion() {
      self.log("migrated from prior state, \(String(describing: migrated))")
      do {
        try self.userDefaults.saveJson(from: migrated, at: State.storageKey)
      } catch {
        self.log("failed to save migrated state: \(error)")
      }
      return migrated
    } else {
      self.log("no state found, or no migration succeeded")
      return nil
    }
  }

  func log(_ message: String) {
    os_log("[G•] %{public}s Migrator: %{public}s", context.uppercased(), message)
  }
}
