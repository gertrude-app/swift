import GertieIOS

public indirect enum ProtectionMode {
  case onboarding([BlockRule])
  case normal([BlockRule])
  case connected([BlockRule], WebContentFilterPolicy)
  // NB: Emergency lockdown represents the state where the app
  // is missing data, and needs to be very restrictive to fail safe.
  // There is a time period while the device is booting, before it
  // is unlocked, where the app can't access UserDefaults
  // @see https://christianselig.com/2024/10/beware-userdefaults/
  // so we fall back to this mode, ideally only for a few seconds.
  case emergencyLockdown
}

public extension ProtectionMode {
  var normalRules: [BlockRule]? {
    switch self {
    case .normal(let rules), .connected(let rules, _): rules
    case .onboarding, .emergencyLockdown: nil
    }
  }

  var rules: [BlockRule]? {
    switch self {
    case .onboarding(let rules): rules
    case .normal(let rules): rules
    case .connected(let rules, _): rules
    case .emergencyLockdown: nil
    }
  }

  var shortDesc: String {
    switch self {
    case .onboarding(let rules):
      ".onboarding(\(rules.count))"
    case .normal(let rules):
      ".normal(\(rules.count))"
    case .connected(let rules, let policy):
      ".connected(\(rules.count), \(policy.shortDesc))"
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
