import Core
import Dependencies
import Gertie
import TestSupport
import XCore
import XCTest
import XExpect

@testable import Filter

class FilterMigratorTests: XCTestCase {
  var testMigrator: FilterMigrator {
    FilterMigrator(userDefaults: .failing)
  }

  func testNoStoredDataAtAllReturnsNil() async {
    var migrator = self.testMigrator
    migrator.userDefaults.getString = { _ in nil }
    let result = await migrator.migrate()
    expect(result).toBeNil()
  }

  func testCurrentStoredDataReturned() async {
    var migrator = self.testMigrator
    let stateJson = try! JSON.encode(Persistent.State.mock)
    let getString = spySync(on: String.self, returning: stateJson)
    migrator.userDefaults.getString = getString.fn
    let result = await migrator.migrate()
    expect(result).toEqual(.mock)
    expect(getString.calls).toEqual(["persistent.state.v2"])
  }

  func testMigratesV1ToV2() async {
    var migrator = self.testMigrator

    let setStringInvocations = LockIsolated<[Both<String, String>]>([])
    migrator.userDefaults.setString = { key, value in
      setStringInvocations.append(.init(key, value))
    }

    let v1FilterKey = RuleKey(id: 1, key: .skeleton(scope: .bundleId("com.whitelisted.widget")))
    let v1Stored = Persistent.V1(
      userKeys: [502: [v1FilterKey]],
      appIdManifest: .init(),
      exemptUsers: [503]
    )

    let getStringInvocations = LockIsolated<[String]>([])
    migrator.userDefaults.getString = { key in
      getStringInvocations.append(key)
      switch key {
      case "persistent.state.v2":
        return nil // <-- no current state
      case "persistent.state.v1":
        return try! JSON.encode(v1Stored)
      default:
        XCTFail("Unexpected key: \(key)")
        return nil
      }
    }

    let expectedState = Persistent.State(
      userKeychains: [502: [.init(
        id: 0, // <-- created by migrator
        schedule: nil,
        keys: [.init(id: v1FilterKey.id, key: v1FilterKey.key)]
      )]],
      userDowntime: [:], // <-- created by migrator
      appIdManifest: v1Stored.appIdManifest,
      exemptUsers: v1Stored.exemptUsers
    )

    let result = await migrator.migrate()
    expect(getStringInvocations.value).toEqual(["persistent.state.v2", "persistent.state.v1"])
    expect(result).toEqual(expectedState)
    expect(setStringInvocations.value).toEqual([Both(
      "persistent.state.v2",
      try! JSON.encode(expectedState)
    )])
  }

  func testMigratesV1Data() async {
    var migrator = self.testMigrator

    let setStringInvocations = LockIsolated<[Both<String, String>]>([])
    migrator.userDefaults.setString = { key, value in
      setStringInvocations.append(.init(key, value))
    }

    let getStringInvocations = LockIsolated<[String]>([])
    migrator.userDefaults.getString = { key in
      getStringInvocations.append(key)
      switch key {
      case "persistent.state.v2":
        return nil // <-- no current state
      case "persistent.state.v1":
        return nil // <-- no v1 state
      case "exemptUsers":
        return "509,507"
      default:
        XCTFail("Unexpected key: \(key)")
        return nil
      }
    }

    let expectedState = Persistent.State(
      userKeychains: [:],
      userDowntime: [:],
      appIdManifest: .init(),
      exemptUsers: [509, 507]
    )

    let result = await migrator.migrate()
    expect(getStringInvocations.value)
      .toEqual(["persistent.state.v2", "persistent.state.v1", "exemptUsers"])
    expect(result).toEqual(expectedState)
    expect(setStringInvocations.value).toEqual([Both(
      "persistent.state.v2",
      try! JSON.encode(expectedState)
    )])
  }
}

extension Persistent.State: Mocked {
  public static var mock: Self {
    .init(
      userKeychains: [502: [.init(id: .deadbeef, schedule: nil, keys: [.mock])]],
      appIdManifest: .empty,
      exemptUsers: [501]
    )
  }

  public static var empty: Self {
    .init(userKeychains: [:], appIdManifest: .empty, exemptUsers: [])
  }
}

extension RuleKey {
  static let mock = RuleKey(
    id: .init(),
    key: .skeleton(scope: .bundleId("com.whitelisted.widget"))
  )
}

extension RuleKeychain {
  static let mock = RuleKeychain(id: .init(), keys: [.mock])
}
