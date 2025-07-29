import Foundation

public enum MagicStrings {
  static let gertrudeBundleIdLong: String = .gertrudeBundleIdLong
  static let gertrudeBundleIdShort: String = .gertrudeBundleIdShort
  static let gertrudeGroupId: String = .gertrudeGroupId
}

public extension String {
  static let gertrudeBundleIdLong = "WFN83LM943.com.netrivet.gertrude-ios.app"
  static let gertrudeBundleIdShort = "com.netrivet.gertrude-ios.app"
  static let gertrudeGroupId = "group.com.netrivet.gertrude-ios.app"
}

public extension UserDefaults {
  static var gertrude: UserDefaults {
    UserDefaults(suiteName: .gertrudeGroupId)!
  }
}

public extension String {
  static var pairqlBase: String {
    "\(String.gertrudeApi)/pairql/ios-app"
  }

  static var gertrudeApi: String {
    (try? Configuration.value(for: "API_URL")) ?? "https://api.gertrude.app"
  }

  static var protectionModeStorageKey: String {
    "ProtectionMode.v1.3.0"
  }

  static var connectionStorageKey: String {
    "ChildIOSDeviceData.v1.5.0"
  }

  static var disabledBlockGroupsStorageKey: String {
    "disabledBlockGroups.v1.3.0"
  }
}

enum Configuration {
  enum Error: Swift.Error {
    case missingKey, invalidValue
  }

  static func value(for key: String) throws -> String {
    guard let object = Bundle.main.object(forInfoDictionaryKey: key) else {
      throw Error.missingKey
    }

    switch object {
    case let string as String:
      return string
    default:
      throw Error.invalidValue
    }
  }
}
