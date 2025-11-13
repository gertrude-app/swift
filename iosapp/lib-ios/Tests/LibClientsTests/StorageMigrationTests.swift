import Dependencies
import Foundation
import GertieIOS
import LibCore
import Testing

@testable import LibClients

@MainActor
@Test func allMigrations() async throws {
  // NB: run from one test to prevent thread contention of group suite
  try await withDependencies {
    $0.api.logEvent = { _, _ in }
    $0.api.fetchDefaultBlockRules = { _ in [.targetContains(value: "def.com")] }
    $0.device.vendorId = { UUID() }
  } operation: {
    try await test_v1_3_to_v15_migration()
    try await test_v1_4_testflight_to_v15_migration()
    try await test_v1_0_to_v15_migration()
  }
}

func test_v1_3_to_v15_migration() async throws {
  let userDefaults = getUserDefaults()

  let rules = ProtectionMode.Legacy.normal([.targetContains("example.com")])
  let jsonData = try JSONEncoder().encode(rules)
  let jsonString = String(data: jsonData, encoding: .utf8)!

  // legacy json, not typescript friendly
  #expect(jsonString.contains("\"_0\":\"example.com\""))

  userDefaults.set(jsonData, forKey: "ProtectionMode.v1.3.0")

  #expect(userDefaults.data(forKey: "v1.5.0--protection-mode") == nil)

  let migrated = await migrateLegacyStorage()
  #expect(migrated == true)

  let migratedData = userDefaults.data(forKey: "v1.5.0--protection-mode")!
  let migratedJson = String(data: migratedData, encoding: .utf8)!

  // typescript friendly
  #expect(migratedJson.contains("\"case\":\"targetContains\""))
  #expect(migratedJson.contains("\"value\":\"example.com\""))
  #expect(!migratedJson.contains("\"_0\":\"example.com\""))

  let decoded = try JSONDecoder().decode(ProtectionMode.self, from: migratedData)
  #expect(decoded == .normal([.targetContains(value: "example.com")]))
}

func test_v1_4_testflight_to_v15_migration() async throws {
  let userDefaults = getUserDefaults()

  let rules = ProtectionMode.normal([.urlContains(value: "test.com")])
  try userDefaults.set(JSONEncoder().encode(rules), forKey: "ProtectionMode.v1.3.0")

  let migrated = await migrateLegacyStorage()
  #expect(migrated == true)

  let migratedData = userDefaults.data(forKey: "v1.5.0--protection-mode")!
  let decoded = try JSONDecoder().decode(ProtectionMode.self, from: migratedData)
  #expect(decoded == rules)
}

func test_v1_0_to_v15_migration() async throws {
  let userDefaults = getUserDefaults()

  // v1.0/1 had some data at "blockRules.v1" key
  let oldV1Data = Data([0x01, 0x02, 0x03])
  userDefaults.set(oldV1Data, forKey: "blockRules.v1")

  let migrated = await migrateLegacyStorage()
  #expect(migrated == true)

  let blockGroupsData = userDefaults.data(forKey: "disabledBlockGroups.v1.3.0")!
  let blockGroups = try JSONDecoder().decode([BlockGroup].self, from: blockGroupsData)
  #expect(blockGroups == [])

  let protectionModeData = userDefaults.data(forKey: "v1.5.0--protection-mode")!
  let protectionMode = try JSONDecoder().decode(ProtectionMode.self, from: protectionModeData)

  switch protectionMode {
  case .normal(let rules):
    #expect(rules == [.targetContains(value: "def.com")])
  default:
    Issue.record("Unexpected protection mode: \(protectionMode)")
  }
}

// helpers

func getUserDefaults() -> UserDefaults {
  let userDefaults = UserDefaults.gertrude
  userDefaults.removePersistentDomain(forName: .gertrudeGroupId)
  return userDefaults
}
