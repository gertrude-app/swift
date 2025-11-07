import Dependencies
import Gertie
import MacAppRoute
import TestSupport
import XCore
import XCTest
import XExpect

@testable import App

class AppMigratorTests: XCTestCase {
  typealias V1 = AppMigrator.Legacy.V1.StorageKey

  var testMigrator: AppMigrator {
    AppMigrator(api: .testValue, userDefaults: .failing)
  }

  func testNoStoredDataAtAllReturnsNil() async {
    var migrator = self.testMigrator
    migrator.userDefaults.getString = { _ in nil }
    let result = await migrator.migrate()
    expect(result).toBeNil()
  }

  func testCurrentStoredDataReturned() async throws {
    var migrator = self.testMigrator
    let stateJson = try JSON.encode(Persistent.State.mock)
    let getString = spySync(on: String.self, returning: stateJson)
    migrator.userDefaults.getString = getString.fn
    let result = await migrator.migrate()
    expect(result).toEqual(.mock)
    expect(getString.calls).toEqual([Persistent.State.storageKey])
  }

  func testMigratesV1Data() async throws {
    var migrator = self.testMigrator

    let setStringInvocations = LockIsolated<[Both<String, String>]>([])
    migrator.userDefaults.setString = { @Sendable key, value in
      setStringInvocations.append(.init(key, value))
    }

    let getStringInvocations = LockIsolated<[String]>([])
    migrator.userDefaults.getString = { key in
      getStringInvocations.append(key)
      switch key {
      case "persistent.state.v2":
        return nil
      case "persistent.state.v1":
        return try! JSON.encode(Persistent.V1(
          appVersion: "2.0.2",
          appUpdateReleaseChannel: .stable,
          user: .empty,
        ))
      default:
        XCTFail("Unexpected key: \(key)")
        return nil
      }
    }

    let result = await migrator.migrate()
    expect(getStringInvocations.value).toEqual(["persistent.state.v2", "persistent.state.v1"])
    expect(result).toEqual(.init(
      appVersion: "2.0.2",
      appUpdateReleaseChannel: .stable,
      filterVersion: "2.0.2",
      user: .empty,
      resumeOnboarding: nil,
    ))
    expect(setStringInvocations.value).toEqual(try [
      Both(
        "persistent.state.v2",
        JSON.encode(Persistent.V2(
          appVersion: "2.0.2",
          appUpdateReleaseChannel: .stable,
          filterVersion: "2.0.2", // <-- transferred
          user: .empty,
          resumeOnboarding: nil,
        )),
      ),
    ])
  }

  func testMigratesLegacyV1DataFromApiCallSuccess() async {
    await withDependencies {
      $0.app.installedVersion = { "1.0.0" }
      $0.device.currentMacOsUserType = { .standard }
      $0.device.osVersion = { .sonoma }
    } operation: {

      var migrator = self.testMigrator

      let apiUser = UserData(
        id: .zeros,
        token: .deadbeef,
        deviceId: .twos,
        name: "Big Mac",
        keyloggingEnabled: true,
        screenshotsEnabled: false,
        screenshotFrequency: 6,
        screenshotSize: 7,
        connectedAt: Date(timeIntervalSince1970: 33),
      )

      let checkIn = spy(
        on: CheckIn_v2.Input.self,
        returning: CheckIn_v2.Output.mock { $0.userData = apiUser },
      )
      migrator.api.checkIn = checkIn.fn

      let setApiToken = spy(on: UUID.self, returning: ())
      migrator.api.setUserToken = setApiToken.fn

      let setStringInvocations = LockIsolated<[Both<String, String>]>([])
      migrator.userDefaults.setString = { @Sendable key, value in
        setStringInvocations.append(.init(key, value))
      }

      let getStringInvocations = LockIsolated<[String]>([])
      migrator.userDefaults.getString = { key in
        getStringInvocations.append(key)
        switch key {
        case "persistent.state.v1":
          return nil
        case "persistent.state.v2":
          return nil
        case V1.userToken.namespaced:
          return UUID.deadbeef.uuidString
        case V1.installedAppVersion.namespaced:
          return "1.77.88"
        default:
          XCTFail("Unexpected key: \(key)")
          return nil
        }
      }

      let result = await migrator.migrate()
      await expect(setApiToken.calls).toEqual([.deadbeef])
      await expect(checkIn.calls.count).toEqual(1)
      expect(getStringInvocations.value).toEqual([
        "persistent.state.v2",
        "persistent.state.v1",
        V1.userToken.namespaced,
        V1.installedAppVersion.namespaced,
      ])
      expect(result).toEqual(.init(
        appVersion: "1.77.88",
        appUpdateReleaseChannel: .stable,
        filterVersion: "1.77.88",
        user: apiUser,
      ))
      expect(setStringInvocations.value).toEqual([
        Both(
          "persistent.state.v2",
          try! JSON.encode(Persistent.V2(
            appVersion: "1.77.88",
            appUpdateReleaseChannel: .stable,
            filterVersion: "1.77.88",
            user: apiUser,
          )),
        ),
      ])
    }
  }

  func testMigratesLegacyV1DataWhenApiCallFails() async {
    await withDependencies {
      $0.app.installedVersion = { "1.0.0" }
      $0.device.currentMacOsUserType = { .standard }
      $0.device.osVersion = { .sonoma }
    } operation: {
      var migrator = self.testMigrator

      // simulate that we can't fetch the user from the api
      // so we need to pull all of the old info from storage
      migrator.api.checkIn = { _ in throw TestErr("oh noes") }

      let setApiToken = spy(on: UUID.self, returning: ())
      migrator.api.setUserToken = setApiToken.fn

      let setStringInvocations = LockIsolated<[Both<String, String>]>([])
      migrator.userDefaults.setString = { @Sendable key, value in
        setStringInvocations.append(.init(key, value))
      }

      let getStringInvocations = LockIsolated<[String]>([])
      migrator.userDefaults.getString = { key in
        getStringInvocations.append(key)
        switch key {
        case "persistent.state.v1":
          return nil
        case "persistent.state.v2":
          return nil
        case V1.userToken.namespaced:
          return UUID.ones.uuidString
        case V1.installedAppVersion.namespaced:
          return "1.77.88"
        case V1.gertrudeUserId.namespaced:
          return UUID.twos.uuidString
        case V1.gertrudeDeviceId.namespaced:
          return UUID.zeros.uuidString
        case V1.keyloggingEnabled.namespaced:
          return "true"
        case V1.screenshotsEnabled.namespaced:
          return "false"
        case V1.screenshotFrequency.namespaced:
          return "444"
        case V1.screenshotSize.namespaced:
          return "777"
        default:
          XCTFail("Unexpected key: \(key)")
          return nil
        }
      }

      let result = await migrator.migrate()
      let expectedUser = UserData(
        id: .twos,
        token: .ones,
        deviceId: .zeros,
        name: "(unknown)",
        keyloggingEnabled: true,
        screenshotsEnabled: false,
        screenshotFrequency: 444,
        screenshotSize: 777,
        connectedAt: Date(timeIntervalSince1970: 0),
      )

      await expect(setApiToken.calls).toEqual([.ones])
      expect(getStringInvocations.value).toEqual([
        "persistent.state.v2",
        "persistent.state.v1",
        V1.userToken.namespaced,
        V1.installedAppVersion.namespaced,
        V1.gertrudeUserId.namespaced,
        V1.gertrudeDeviceId.namespaced,
        V1.keyloggingEnabled.namespaced,
        V1.screenshotsEnabled.namespaced,
        V1.screenshotFrequency.namespaced,
        V1.screenshotSize.namespaced,
      ])
      expect(result).toEqual(.init(
        appVersion: "1.77.88",
        appUpdateReleaseChannel: .stable,
        filterVersion: "1.77.88",
        user: expectedUser,
      ))
      expect(setStringInvocations.value).toEqual([Both(
        "persistent.state.v2",
        try! JSON.encode(Persistent.V2(
          appVersion: "1.77.88",
          appUpdateReleaseChannel: .stable,
          filterVersion: "1.77.88",
          user: expectedUser,
        )),
      )])
    }
  }
}
