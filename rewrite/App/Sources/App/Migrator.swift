import ClientInterfaces
import Core
import os.log
import Gertie
import XCore

struct Migrator {
  var api: ApiClient
  var userDefaults: UserDefaultsClient

  func migratePersistedState() async -> Persistent.State? {
    // `v1` here means version 1 of Persistent.State, introduced in app 2.0.0
    let key = "persistent.state.v1"
    let current = try? userDefaults.getString(key).flatMap { json in
      try JSON.decode(json, as: Persistent.State.self)
    }
    if let current {
      os_log("[G•] Migrator: found current state, no migration necessary")
      return current
    } else if let migrated = await migrateV1() {
      os_log("[G•] Migrator: migrated from V1 state - %{public}s", String(describing: migrated))
      (try? JSON.encode(migrated)).map { userDefaults.setString(key, $0) }
      return migrated
    } else {
      os_log("[G•] Migrator: no state found, no migration succeeded")
      return nil
    }
  }

  // v1 below refers to legacy 1.x version of the app
  // before ComposableArchitecture rewrite
  func migrateV1() async -> Persistent.State? {
    typealias V1 = LegacyData.V1

    guard let token = userDefaults
      .v1(.userToken)
      .flatMap(UUID.init(uuidString:)) else {
      return nil
    }

    await api.setUserToken(token)
    let user = try? await api.userData()
    let v1Version = userDefaults.v1(.installedAppVersion) ?? "unknown"

    if let user {
      return Persistent.State(
        appVersion: v1Version,
        appUpdateReleaseChannel: .stable,
        user: user
      )
    }

    guard let userIdString = userDefaults.v1(.gertrudeUserId),
          let userId = UUID(uuidString: userIdString),
          let deviceIdString = userDefaults.v1(.gertrudeDeviceId),
          let deviceId = UUID(uuidString: deviceIdString) else {
      return nil
    }

    let keyloggingEnabled = userDefaults.v1(.keyloggingEnabled).flatMap(V1.toBool)
    let screenshotsEnabled = userDefaults.v1(.screenshotsEnabled).flatMap(V1.toBool)
    let screenshotsFrequency = userDefaults.v1(.screenshotFrequency).flatMap(Int.init)
    let screenshotsSize = userDefaults.v1(.screenshotSize).flatMap(Int.init)

    return Persistent.State(
      appVersion: v1Version,
      appUpdateReleaseChannel: .stable,
      user: UserData(
        id: userId,
        token: token,
        deviceId: deviceId,
        name: "(unknown)",
        keyloggingEnabled: keyloggingEnabled ?? true,
        screenshotsEnabled: screenshotsEnabled ?? true,
        screenshotFrequency: screenshotsFrequency ?? 60,
        screenshotSize: screenshotsSize ?? 1000,
        connectedAt: Date(timeIntervalSince1970: 0)
      )
    )
  }
}

private extension UserDefaultsClient {
  func v1(_ key: Migrator.LegacyData.V1.StorageKey) -> String? {
    getString(key.namespaced)
  }
}

extension Migrator {
  enum LegacyData {
    enum V1 {
      enum StorageKey: String {
        case gertrudeUserId
        case gertrudeDeviceId
        case filterRestartFailsafe
        case installedAppVersion
        case userToken = "guardianToken"
        case keyloggingEnabled
        case screenshotsEnabled
        case screenshotFrequency
        case screenshotSize
        case graphQLEndpointOverride
        case pairQLEndpointOverride
        case websocketEndpointOverride
        case appcastEndpointOverride
        case releaseChannel

        var namespaced: String {
          "device_storage.\(rawValue)"
        }
      }

      static func toBool(_ string: String?) -> Bool? {
        switch string {
        case "true":
          return true
        case "false":
          return false
        default:
          return nil
        }
      }
    }
  }
}
