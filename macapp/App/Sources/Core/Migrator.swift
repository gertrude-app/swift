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
    let key = "persistent.state.v\(State.version)"
    let current = try? userDefaults.getString(key).flatMap { json in
      try JSON.decode(json, as: State.self)
    }
    if let current {
      log("found current state, no migration necessary")
      return current
    } else if let migrated = await migrateLastVersion() {
      log("migrated from prior state, \(String(describing: migrated))")
      (try? JSON.encode(migrated)).map { userDefaults.setString(key, $0) }
      return migrated
    } else {
      log("no state found, or migration succeeded")
      return nil
    }
  }

  func log(_ message: String) {
    os_log("[G•] Migrator (%{public}s): %{public}s", context, message)
  }
}
