import ClientInterfaces
import Core
import Gertie
import XCore

struct AppMigrator: Migrator {
  var api: ApiClient
  var userDefaults: UserDefaultsClient
  var context = "App"

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
    return .init(
      appVersion: v1.appVersion,
      appUpdateReleaseChannel: v1.appUpdateReleaseChannel,
      filterVersion: v1.appVersion,
      user: v1.user
    )
  }

  // v1 below refers to legacy 1.x version of the app
  // before ComposableArchitecture rewrite
  func migrateV1() async -> Persistent.V1? {
    typealias V1 = Legacy.V1

    guard let token = userDefaults
      .v1(.userToken)
      .flatMap(UUID.init(uuidString:)) else {
      return nil
    }

    log("found v1 token `\(token)`")
    await self.api.setUserToken(token)
    let user = (try? await api.appCheckIn(nil))?.userData
    let v1Version = self.userDefaults.v1(.installedAppVersion) ?? "unknown"

    if let user {
      log("migrated v1 state from successful user api call")
      return Persistent.V1(
        appVersion: v1Version,
        appUpdateReleaseChannel: .stable,
        user: user
      )
    }

    log("api call failed, migrating v1 state from storage")

    guard let userIdString = userDefaults.v1(.gertrudeUserId),
          let userId = UUID(uuidString: userIdString),
          let deviceIdString = userDefaults.v1(.gertrudeDeviceId),
          let deviceId = UUID(uuidString: deviceIdString) else {
      log("missing required date to continue storage migration")
      return nil
    }

    let keyloggingEnabled = self.userDefaults.v1(.keyloggingEnabled).flatMap(V1.toBool)
    let screenshotsEnabled = self.userDefaults.v1(.screenshotsEnabled).flatMap(V1.toBool)
    let screenshotsFrequency = self.userDefaults.v1(.screenshotFrequency).flatMap(Int.init)
    let screenshotsSize = self.userDefaults.v1(.screenshotSize).flatMap(Int.init)

    log("migrated v1 state from fallback storage")
    return Persistent.V1(
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
  func v1(_ key: AppMigrator.Legacy.V1.StorageKey) -> String? {
    getString(key.namespaced)
  }
}

extension AppMigrator {
  enum Legacy {
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
