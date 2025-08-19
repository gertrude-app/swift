import Foundation
import GertieIOS

public extension BlockRule {
  func blocksFlow(_ flow: FilterFlow) -> Bool {
    let hostname = flow.hostname ?? flow.url.flatMap {
      guard $0.hasPrefix("http://") || $0.hasPrefix("https://") else { return nil }
      return URL(string: $0)?.host
    }
    let target = flow.url ?? flow.hostname
    switch self {
    case .bundleIdContains(let fragment):
      return flow.bundleId?.contains(fragment) == true
    case .targetContains(let fragment):
      return target?.contains(fragment) == true
    case .urlContains(let fragment):
      return flow.url?.contains(fragment) == true
    case .hostnameContains(let fragment):
      return hostname?.contains(fragment) == true
    case .hostnameEquals(let fragment):
      return hostname == fragment
    case .hostnameEndsWith(let fragment):
      return hostname?.hasSuffix(fragment) == true
    case .flowTypeIs(let type):
      return flow.flowType == type
    case .both(let a, let b):
      return a.blocksFlow(flow) && b.blocksFlow(flow)
    case .unless(let rule, let negatedBy):
      if rule.blocksFlow(flow) {
        return !negatedBy.blocksFlow(flow)
      } else {
        return false
      }
    }
  }
}

public extension [BlockRule] {
  func blocksFlow(_ flow: FilterFlow) -> Bool {
    self.contains { rule in
      rule.blocksFlow(flow)
    }
  }
}
