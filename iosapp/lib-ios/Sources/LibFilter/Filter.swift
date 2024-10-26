import GertieIOS

extension BlockRule {
  func blocksFlow(target: String?, url: String?, bundleId: String?) -> Bool {
    switch self {
    case .bundleIdContains(let fragment):
      return bundleId?.contains(fragment) == true
    case .targetContains(let fragment):
      return target?.contains(fragment) == true
    case .urlContains(let fragment):
      return url?.contains(fragment) == true
    case .both(let a, let b):
      return a.blocksFlow(target: target, url: url, bundleId: bundleId)
        && b.blocksFlow(target: target, url: url, bundleId: bundleId)
    }
  }
}

public extension Array where Element == BlockRule {
  func blocksFlow(hostname: String?, url: String?, bundleId: String?) -> Bool {
    let target = url ?? hostname
    return self.contains { rule in
      rule.blocksFlow(target: target, url: url, bundleId: bundleId)
    }
  }
}
