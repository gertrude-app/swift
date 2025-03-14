import Foundation
import GertieIOS

public enum ProtectionMode {
  case onboarding([BlockRule])
  case normal([BlockRule])
  case emergencyLockdown
}

public extension ProtectionMode {
  var normalRules: [BlockRule]? {
    switch self {
    case .normal(let rules):
      return rules
    case .onboarding, .emergencyLockdown:
      return nil
    }
  }

  var rules: [BlockRule]? {
    switch self {
    case .onboarding(let rules):
      return rules
    case .normal(let rules):
      return rules
    case .emergencyLockdown:
      return nil
    }
  }
}

extension ProtectionMode: Equatable, Sendable, Codable {}

public extension Optional where Wrapped == ProtectionMode {
  var missingRules: Bool {
    switch self {
    case .none:
      return true
    case .some(.emergencyLockdown):
      return true
    case .some(.onboarding([])):
      return true
    case .some(.normal([])):
      return true
    default:
      return false
    }
  }
}

public extension UserDefaults {
  static let gertrude = UserDefaults(suiteName: "group.com.netrivet.gertrude-ios.app")!
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

  static var disabledBlockGroupsStorageKey: String {
    "disabledBlockGroups.v1.3.0"
  }
}
