import Foundation

public enum FilterStorageKey {
  case idManifest
  case userKeys(uid_t)
  case exemptUsers
  case usersWithKeys
  case consoleLoggingConfig
  case honeycombLoggingConfig

  public var string: String {
    switch self {
    case .idManifest:
      return "idManifest_06_2022"
    case .exemptUsers:
      return "exemptUsers"
    case .usersWithKeys:
      return "usersWithKeys"
    case .userKeys(let id):
      return "userKeys:\(id)"
    case .consoleLoggingConfig:
      return "consoleLoggingConfig_09_2022"
    case .honeycombLoggingConfig:
      return "honeycombLoggingConfig_09_2022"
    }
  }

  public var stableString: String {
    switch self {
    case .userKeys:
      return "userKeys:<id>"
    case .idManifest,
         .exemptUsers,
         .usersWithKeys,
         .consoleLoggingConfig,
         .honeycombLoggingConfig:
      return string
    }
  }

  public static var purgeKeys: [String] {
    switch FilterStorageKey.idManifest {
    case .idManifest,
         .userKeys,
         .exemptUsers,
         .usersWithKeys,
         .consoleLoggingConfig,
         .honeycombLoggingConfig:
      // only add a new case above if you have also
      // handled it in the keys string assembly code below
      // switch just exists to force a compile error if
      // i forget to do this step
      break
    }

    var keys: [String] = [
      Self.idManifest.string,
      Self.exemptUsers.string,
      Self.usersWithKeys.string,
      Self.consoleLoggingConfig.string,
      Self.honeycombLoggingConfig.string,
    ]
    // covers user ids from 500 - 520, should be enough
    for num in 0 ... 20 {
      keys.append(Self.userKeys(.init(num)).string)
    }
    return keys
  }
}
