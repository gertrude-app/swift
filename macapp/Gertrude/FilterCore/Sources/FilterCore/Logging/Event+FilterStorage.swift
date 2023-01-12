import Foundation
import Shared
import SharedCore

public enum FilterStorageEvent: LogMessagable {
  case missingData(Codable.Type, FilterStorageKey)
  case missingUserData(uid_t, Codable.Type, FilterStorageKey)
  case load(Decodable.Type, FilterStorageKey, String)
  case save(Encodable.Type, FilterStorageKey, String)
  case loadForUser(uid_t, Decodable.Type, FilterStorageKey, String)
  case saveForUser(uid_t, Encodable.Type, FilterStorageKey, String)
  case loadUserKeys(uid_t, Int)
  case saveUserKeys(uid_t, Int)
  case addUserWithKeys(uid_t, String)
  case emptyKeys(uid_t)
  case addExemptUser(uid_t)
  case purgeAll
  case removeExemptUsers

  public var logMessage: Log.Message {
    switch self {
    case .missingData(let type, let key):
      return .notice("no \(type) data from key \(key.stableString) to load")
    case .missingUserData(let userId, let type, let key):
      return .notice(
        "no user-specific \(type) data from key \(key.stableString) to load",
        .userId(userId)
      )
    case .load(let type, let key, let json):
      return .info("load \(type) from key \(key.stableString)", .json(json))
    case .save(let type, let key, let json):
      return .info("save \(type) to key \(key.stableString)", .json(json))
    case .loadUserKeys(let userId, let keyCount):
      return .info("load user keys", .primary(["user_id": Int(userId), "num_keys": keyCount]))
    case .saveUserKeys(let userId, let keyCount):
      return .info("save user keys", .primary(["user_id": Int(userId), "num_keys": keyCount]))
    case .loadForUser(let userId, let type, let key, let json):
      return .info(
        "load \(type) for user from key \(key.stableString)",
        .json(json) + .userId(userId)
      )
    case .saveForUser(let userId, let type, let key, let json):
      return .info(
        "save \(type) for user to key \(key.stableString)",
        .json(json) + .userId(userId)
      )
    case .emptyKeys(let userId):
      return .error("empty keys array", .userId(userId))
    case .addUserWithKeys(let userId, let idsCsv):
      return .info("add user with keys", .primary("{\"added_id\":\(userId),\"ids\":\"\(idsCsv)}\""))
    case .addExemptUser(let userId):
      return .info("add exempt user", .userId(userId))
    case .removeExemptUsers:
      return .info("removed all exempt users")
    case .purgeAll:
      return .warn("purged all data")
    }
  }
}
