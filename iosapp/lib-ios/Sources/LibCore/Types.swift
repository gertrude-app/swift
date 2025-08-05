import Foundation

public enum MagicStrings {
  public static let gertrudeBundleIdLong: String = .gertrudeBundleIdLong
  public static let gertrudeBundleIdShort: String = .gertrudeBundleIdShort
  public static let gertrudeGroupId: String = .gertrudeGroupId

  // sentinal hostnames
  public static let readRulesSentinalHostname: String = "read-rules.xpc.gertrude.app"
  public static let dumpLogsSentinalHostname: String = "dump-logs.xpc.gertrude.app"
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

public extension Array {
  func chunked(into size: Int) -> [[Element]] {
    stride(from: 0, to: count, by: size).map {
      Array(self[$0 ..< Swift.min($0 + size, count)])
    }
  }
}
