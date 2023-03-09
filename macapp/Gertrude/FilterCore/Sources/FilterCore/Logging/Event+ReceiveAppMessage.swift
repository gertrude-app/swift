import Foundation
import Shared
import SharedCore
import XCore

public enum ReceiveAppMessageEvent: LogMessagable {
  case setFilterSuspension(FilterSuspension, uid_t)
  case cancelSuspension(uid_t)
  case unexpectedEmptyExemptUserList(String)
  case exemptUsers(Set<uid_t>)
  case refreshRulesKeys(uid_t, Int)
  case refreshRulesAppIdManifest(AppIdManifest)
  case transmitNumKeysLoaded(uid_t, Int)
  case transmitCurrentVersion(String)
  case confirmCommunication(Int)
  case loggingCommand(AppToFilterLoggingCommand)
  case clearExemptUsers
  case register
  case purgeAllDeviceStorage

  public var logMessage: Log.Message {
    switch self {
    case .loggingCommand(.startAppWindowLogging):
      return .notice("logging command: start app window logging")
    case .loggingCommand(.stopAppWindowLogging):
      return .notice("logging command: stop app window logging")
    case .loggingCommand(.endDebugSession):
      return .notice("logging command: end debug session")
    case .loggingCommand(.startDebugSession(let session)):
      return .notice("logging command: start debug session", [
        "meta.primary": .string(session.id.lowercased),
        "meta.debug": .string("\(session.expiration)"),
      ])
    case .loggingCommand(.setPersistentConsoleConfig(let config)):
      return .notice("logging command: set persistent console config", [
        "json.raw": .init(try? JSON.encode(config)),
      ])
    case .loggingCommand(.setPersistentHoneycombConfig(let config)):
      return .notice("logging command: set persistent honeycomb config", [
        "json.raw": .init(try? JSON.encode(config)),
      ])

    case .setFilterSuspension(let suspension, let userId):
      return .notice("set filter suspension", .userId(userId) + .json(try? JSON.encode(suspension)))

    case .cancelSuspension(let userId):
      return .notice("cancel filter suspension", .userId(userId))

    case .register:
      return .notice("app registered with filter extension")

    case .unexpectedEmptyExemptUserList(let csv):
      return .error("unexpected empty exempt user list", .primary(["csv": csv]))

    case .exemptUsers(let ids):
      return .notice(
        "exempt users",
        .primary(["users_ids": ids.map { "\($0)" }.joined(separator: ",")])
      )

    case .refreshRulesKeys(let userId, let numKeys):
      return .notice("refresh rules keys", .primary(["user_id": Int(userId), "num_keys": numKeys]))

    case .clearExemptUsers:
      return .notice("clear exempt users")

    case .refreshRulesAppIdManifest(let manifest):
      let totalCount = manifest.apps.count + manifest.categories.count + manifest.displayNames.count
      return .notice("refresh rules app id manifest", .primary(["total_count": totalCount]))

    case .transmitNumKeysLoaded(let userId, let numKeys):
      return .info(
        "transmit num keys loaded",
        .primary(["user_id": Int(userId), "num_keys": numKeys])
      )

    case .transmitCurrentVersion(let version):
      return .info("transmit current version", .primary(["version": version]))

    case .confirmCommunication(let randomInt):
      return .info("confirm communication", .primary(["random_int": randomInt]))
    case .purgeAllDeviceStorage:
      return .warn("purge all device data")
    }
  }
}

public enum ReceiveAppMessageDebugEvent: LogMessagable {
  case refreshRulesKeys(uid_t, [FilterKey])
  case refreshRulesAppIdManifest(AppIdManifest)

  public var logMessage: Log.Message {
    switch self {
    case .refreshRulesKeys(let userId, let keys):
      return .debug(
        "refresh rules keys",
        [
          "meta.primary": .string("user_id=\(userId), keys in `meta.debug`"),
          "meta.debug": .init(keys.map(\.id.lowercased)),
        ]
      )
    case .refreshRulesAppIdManifest(let manifest):
      return .debug("refresh rules app id", ["meta.debug": .init(manifest)])
    }
  }
}
