import SharedCore

public class DecisionBag {
  public init(decisions: [FilterDecision] = []) {
    self.decisions = decisions
  }

  private var decisions: [FilterDecision] = []
  public var count: Int { decisions.count }

  public func push(_ decision: FilterDecision) {
    if let last = decisions.last, mergable(last, decision) {
      decisions[decisions.count - 1].count += 1
      return
    }

    decisions.append(decision)
  }

  public func flushRecentFirst() -> [FilterDecision] {
    defer { decisions = [] }
    return decisions.reversed()
  }
}

// helpers

private func mergable(_ a: FilterDecision, _ b: FilterDecision) -> Bool {
  let mostFieldsEqual =
    a.hostname == b.hostname
      && a.bundleId == b.bundleId
      && a.verdict == b.verdict
      && a.reason == b.reason
      && a.ipProtocol == b.ipProtocol
      && a.responsibleKeyId == b.responsibleKeyId

  if !mostFieldsEqual {
    return false
  }

  if a.ipAddress == b.ipAddress, a.url == b.url {
    return true
  }

  // if we happen to have a full url for both, and they
  // are the same, but with different ip addresses, merge
  if let aUrl = a.url, let bUrl = b.url, aUrl == bUrl {
    return true
  }

  return false
}
