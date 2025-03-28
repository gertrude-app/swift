import Foundation
import GertieIOS

public extension BlockRule {
  func blocksFlow(
    hostname rawHostname: String?,
    url: String?,
    bundleId: String?,
    flowType: FlowType?
  ) -> Bool {
    let hostname = rawHostname ?? url.flatMap {
      guard $0.hasPrefix("http://") || $0.hasPrefix("https://") else { return nil }
      return URL(string: $0)?.host
    }
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
    case .flowTypeIs(let type):
      return flowType == type
    case .both(let a, let b):
      return a.blocksFlow(hostname: hostname, url: url, bundleId: bundleId, flowType: flowType)
        && b.blocksFlow(hostname: hostname, url: url, bundleId: bundleId, flowType: flowType)
    case .unless(let rule, let negatedBy):
      if rule.blocksFlow(hostname: hostname, url: url, bundleId: bundleId, flowType: flowType) {
        return !negatedBy.blocksFlow(
          hostname: hostname,
          url: url,
          bundleId: bundleId,
          flowType: flowType
        )
      } else {
        return false
      }
    }
  }
}

public extension [BlockRule] {
  func blocksFlow(
    hostname: String?,
    url: String?,
    bundleId: String?,
    flowType: FlowType?
  ) -> Bool {
    self.contains { rule in
      rule.blocksFlow(hostname: hostname, url: url, bundleId: bundleId, flowType: flowType)
    }
  }
}
