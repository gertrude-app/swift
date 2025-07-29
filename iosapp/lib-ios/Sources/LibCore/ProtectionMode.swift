import GertieIOS

public indirect enum ProtectionMode {
  case onboarding([BlockRule])
  case normal([BlockRule])
  case connected([BlockRule], WebContentFilterPolicy)
  case emergencyLockdown
}

public extension ProtectionMode {
  // FIXME: necessary any more?
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
