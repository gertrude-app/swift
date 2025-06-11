import Foundation
import GertieIOS

public indirect enum ProtectionMode {
  case onboarding([BlockRule])
  case normal([BlockRule])
  case emergencyLockdown
}

public extension ProtectionMode {
  var normalRules: [BlockRule]? {
    switch self {
    case .normal(let rules):
      rules
    case .onboarding, .emergencyLockdown:
      nil
    }
  }

  var rules: [BlockRule]? {
    switch self {
    case .onboarding(let rules):
      rules
    case .normal(let rules):
      rules
    case .emergencyLockdown:
      nil
    }
  }

  var shortDesc: String {
    switch self {
    case .onboarding(let rules):
      ".onboarding(\(rules.count))"
    case .normal(let rules):
      ".normal(\(rules.count))"
    case .emergencyLockdown:
      ".emergencyLockdown"
    }
  }
}

extension ProtectionMode: Equatable, Sendable, Codable {}

public extension ProtectionMode? {
  var missingRules: Bool {
    switch self {
    case .none:
      true
    case .some(.emergencyLockdown):
      true
    case .some(.onboarding([])):
      true
    case .some(.normal([])):
      true
    default:
      false
    }
  }
}

public extension UserDefaults {
  static var gertrude: UserDefaults {
    UserDefaults(suiteName: "group.com.netrivet.gertrude-ios.app")!
  }
}

public extension String {
  static var pairqlBase: String {
    "\(String.gertrudeApi)/pairql/ios-app"
  }

  static var gertrudeApi: String {
    #if DEBUG
      // just run-api-ip
      "http://192.168.10.227:8080"
    #else
      "https://api.gertrude.app"
    #endif
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
