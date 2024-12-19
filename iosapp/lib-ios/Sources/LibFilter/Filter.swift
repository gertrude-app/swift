import GertieIOS

public extension BlockRule {
  func blocksFlow(hostname: String?, url: String?, bundleId: String?) -> Bool {
    let target = url ?? hostname
    switch self {
    case .bundleIdContains(let fragment):
      return bundleId?.contains(fragment) == true
    case .targetContains(let fragment):
      return target?.contains(fragment) == true
    case .urlContains(let fragment):
      return url?.contains(fragment) == true
    case .hostnameContains(let fragment):
      return hostname?.contains(fragment) == true
    case .hostnameEquals(let fragment):
      return hostname == fragment
    case .hostnameEndsWith(let fragment):
      return hostname?.hasSuffix(fragment) == true
    case .both(let a, let b):
      return a.blocksFlow(hostname: hostname, url: url, bundleId: bundleId)
        && b.blocksFlow(hostname: hostname, url: url, bundleId: bundleId)
    case .unless(let rule, let negatedBy):
      if rule.blocksFlow(hostname: hostname, url: url, bundleId: bundleId) {
        return !negatedBy.blocksFlow(hostname: hostname, url: url, bundleId: bundleId)
      } else {
        return false
      }
    }
  }
}

public extension Array where Element == BlockRule {
  func blocksFlow(hostname: String?, url: String?, bundleId: String?) -> Bool {
    self.contains { rule in
      rule.blocksFlow(hostname: hostname, url: url, bundleId: bundleId)
    }
  }
}
