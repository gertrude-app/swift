import Core
import os.log
import XCore

struct FilterMigrator: Migrator {
  var userDefaults: UserDefaultsClient
  var context = "Filter"

  func migrateLastVersion() async -> Persistent.State? {
    await self.migrateV2()
  }

  func migrateV2() async -> Persistent.V2? {
    var v1 = try? self.userDefaults.getString(Persistent.V1.storageKey).flatMap { json in
      try JSON.decode(json, as: Persistent.V1.self)
    }
    if v1 == nil {
      v1 = await self.migrateV1()
    }
    guard let v1 else { return nil }
    log("migrating v1 state to v2")
    return .init(
      userKeys: v1.userKeys,
      userDowntime: [:],
      appIdManifest: v1.appIdManifest,
      exemptUsers: v1.exemptUsers
    )
  }

  // v1 below refers to legacy 1.x version of the app
  // before ComposableArchitecture rewrite
  func migrateV1() async -> Persistent.V1? {
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
