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
    var migrator = testMigrator
    migrator.userDefaults.getString = { _ in nil }
    let result = await migrator.migrate()
    expect(result).toBeNil()
  }

  func testCurrentStoredDataReturned() async {
    var migrator = testMigrator
    let stateJson = try! JSON.encode(Persistent.State.mock)
    let getString = spySync(on: String.self, returning: stateJson)
    migrator.userDefaults.getString = getString.fn
    let result = await migrator.migrate()
    expect(result).toEqual(.mock)
    expect(getString.invocations.value).toEqual(["persistent.state.v1"])
  }

  func testMigratesV1Data() async {
    var migrator = testMigrator

    let setStringInvocations = LockIsolated<[Both<String, String>]>([])
    migrator.userDefaults.setString = { key, value in
      setStringInvocations.append(.init(key, value))
    }

    let getStringInvocations = LockIsolated<[String]>([])
    migrator.userDefaults.getString = { key in
      getStringInvocations.append(key)
      switch key {
      case "persistent.state.v1":
        return nil // <-- no current state
      case "exemptUsers":
        return "509,507"
      default:
        XCTFail("Unexpected key: \(key)")
        return nil
      }
    }

    let expectedState = Persistent.State(
      userKeys: [:],
      appIdManifest: .init(),
      exemptUsers: [509, 507]
    )

    let result = await migrator.migrate()
    expect(getStringInvocations.value).toEqual(["persistent.state.v1", "exemptUsers"])
    expect(result).toEqual(expectedState)
    expect(setStringInvocations.value).toEqual([Both(
      "persistent.state.v1",
      try! JSON.encode(expectedState)
    )])
  }
}

extension Persistent.State: Mocked {
  public static var mock: Self {
    .init(
      userKeys: [502: [.init(id: .deadbeef, key: .mock)]],
      appIdManifest: .empty,
      exemptUsers: [501]
    )
  }

  public static var empty: Self {
    .init(userKeys: [:], appIdManifest: .empty, exemptUsers: [])
  }
}
