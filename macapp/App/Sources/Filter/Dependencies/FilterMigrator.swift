import Core
import os.log
import XCore

struct FilterMigrator {
  var userDefaults: UserDefaultsClient

  func migrateLastVersion() -> Persistent.State? {
    migrateV1()
  }

  // v1 below refers to legacy 1.x version of the app
  // before ComposableArchitecture rewrite
  func migrateV1() -> Persistent.State? {
    guard let exemptUserIds = userDefaults.getString("exemptUsers") else {
      return nil
    }
    log("migrating v1 recovered exempt users: \(exemptUserIds)")
    return .init(
      userKeys: [:],
      appIdManifest: .init(),
      exemptUsers: Legacy.V1.parseCommaSeparatedUserIds(exemptUserIds)
    )
  }

  func migrate() -> Persistent.State? {
    let key = "persistent.state.v\(Persistent.State.version)"
    let current = try? userDefaults.getString(key).flatMap { json in
      try JSON.decode(json, as: Persistent.State.self)
    }
    if let current {
      log("found current state, no migration necessary")
      return current
    } else if let migrated = migrateLastVersion() {
      log("migrated from prior state, \(String(describing: migrated))")
      (try? JSON.encode(migrated)).map { userDefaults.setString(key, $0) }
      return migrated
    } else {
      log("no state found, or migration succeeded")
      return nil
    }
  }

  func log(_ message: String) {
    os_log("[G•] FilterMigrator: %{public}s", message)
  }
}

extension FilterMigrator {
  enum Legacy {
    enum V1 {
      static func parseCommaSeparatedUserIds(_ csv: String) -> Set<uid_t> {
        Set(
          csv.trimmingCharacters(in: .whitespaces)
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0 != "" }
            .compactMap { UInt32($0) as uid_t? }
        )
      }
    }
  }
}
